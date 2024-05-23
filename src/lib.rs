mod types;

#[macro_export]
macro_rules! kaf_unwrap {
    ($e:expr) => {
        match $e {
            Ok(data) => data,
            Err(e) => return LuaResult::Err(mlua::Error::RuntimeError(e.to_string())),
        }
    };
}

#[macro_export]
macro_rules! kaf_rd_unwrap {
    ($e:expr) => {
        match $e {
            Ok(data) => data,
            Err((e, _)) => return LuaResult::Err(mlua::Error::RuntimeError(format!("{:?}", e))),
        }
    };
}
use mlua::prelude::*;

use rdkafka::admin::{AdminClient, AdminOptions};
use rdkafka::config::{ClientConfig, FromClientConfig};
use rdkafka::consumer::{BaseConsumer, Consumer, ConsumerContext};
use rdkafka::producer::{BaseProducer, BaseRecord, Producer};
use rdkafka::{ClientContext, Offset, TopicPartitionList};

use std::collections::HashMap;
use std::time::Duration;

use crate::types::input::{CreateTopicData, DeleteTopicData, ListMessagesData, ListTopicsData};
use crate::types::output::{vec_to_table, Message, Topic};

struct CustomConsumerContext;

impl ClientContext for CustomConsumerContext {}

impl ConsumerContext for CustomConsumerContext {
    fn pre_rebalance(&self, _rebalance: &rdkafka::consumer::Rebalance) {}
}

fn internal_topics<'a>(lua: &'a Lua, data: ListTopicsData) -> LuaResult<LuaValue<'a>> {
    let mut consumer_config = ClientConfig::new();
    consumer_config
        .set("bootstrap.servers", data.brokers.join(","))
        .set("enable.auto.commit", "false")
        .set("group.id", "kaf.nvim");
    let consumer_context = CustomConsumerContext;
    let consumer: BaseConsumer<_> =
        kaf_unwrap!(consumer_config.create_with_context(consumer_context));

    let metadata = kaf_unwrap!(consumer.fetch_metadata(None, std::time::Duration::from_secs(10)));

    let mut topics = vec![];
    for topic in metadata.topics() {
        topics.push(Topic {
            name: topic.name().to_string(),
            partitions: topic.partitions().len(),
        });
    }

    vec_to_table(lua, topics)
}

fn topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaValue<'a>> {
    let data = ListTopicsData::from_lua(LuaValue::Table(opts), lua)?;
    internal_topics(lua, data)
}

fn internal_messages<'a>(lua: &'a Lua, data: &ListMessagesData) -> LuaResult<LuaValue<'a>> {
    let mut consumer_config = ClientConfig::new();
    consumer_config
        .set("bootstrap.servers", data.brokers.join(","))
        .set("enable.auto.commit", "false")
        .set("group.id", "kaf.nvim");

    let consumer_context = CustomConsumerContext;
    let consumer: BaseConsumer<_> =
        kaf_unwrap!(consumer_config.create_with_context(consumer_context));

    kaf_unwrap!(consumer.subscribe(&[data.topic.as_str()]));

    let metadata =
        kaf_unwrap!(consumer.fetch_metadata(Some(data.topic.as_str()), Duration::from_secs(10)));

    let mut max_messages_partition = HashMap::new();

    let mut topic_partitions = TopicPartitionList::new();
    for metadata_topic in metadata.topics() {
        for partition in metadata_topic.partitions() {
            let (low, high) = kaf_unwrap!(consumer.fetch_watermarks(
                metadata_topic.name(),
                partition.id(),
                Duration::from_secs(10)
            ));

            let count_messages = high - low;
            let offset = if count_messages > data.max_messages_per_partition {
                high - data.max_messages_per_partition
            } else {
                low
            };

            kaf_unwrap!(topic_partitions.add_partition_offset(
                metadata_topic.name(),
                partition.id(),
                Offset::Offset(offset),
            ));

            let max_messages = data.max_messages_per_partition.min(count_messages);
            max_messages_partition.insert(partition.id(), max_messages);
        }
    }

    kaf_unwrap!(consumer.assign(&topic_partitions));
    let mut messages: Vec<Message> = vec![];

    loop {
        match consumer.poll(Duration::from_secs(2)) {
            Some(Ok(message)) => match rdkafka::Message::payload_view::<str>(&message) {
                Some(payload) => {
                    let key = match rdkafka::Message::key(&message) {
                        Some(key) => Some(kaf_unwrap!(std::str::from_utf8(key)).to_owned()),
                        None => None,
                    };

                    let timestamp = match rdkafka::Message::timestamp(&message) {
                        rdkafka::Timestamp::NotAvailable => None,
                        rdkafka::Timestamp::CreateTime(value) => Some(value),
                        rdkafka::Timestamp::LogAppendTime(value) => Some(value),
                    };

                    messages.push(Message {
                        key,
                        partition: rdkafka::Message::partition(&message),
                        timestamp,
                        offset: rdkafka::Message::offset(&message),
                        value: kaf_unwrap!(payload).to_owned(),
                    });

                    max_messages_partition
                        .get_mut(&rdkafka::Message::partition(&message))
                        .map(|x| *x -= 1);

                    if !max_messages_partition
                        .iter()
                        .any(|(_key, value)| *value > 0)
                    {
                        break;
                    }
                }
                None => break,
            },
            _ => break,
        }
    }

    vec_to_table(lua, messages)
}

fn messages<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaValue<'a>> {
    let message_data = ListMessagesData::from_lua(LuaValue::Table(opts), lua)?;
    internal_messages(lua, &message_data)
}

fn internal_producer<'a>(_lua: &'a Lua, data: types::input::ProduceMessageData) -> LuaResult<()> {
    let mut producer_config = ClientConfig::new();
    producer_config.set("bootstrap.servers", data.brokers.join(","));
    let producer: BaseProducer = kaf_unwrap!(producer_config.create());

    kaf_rd_unwrap!(producer.send(
        BaseRecord::to(data.topic.as_str())
            .key(match data.key {
                Some(ref key) => key.as_str(),
                None => "",
            })
            .payload(data.value.as_str()),
    ));

    kaf_unwrap!(producer.flush(Duration::from_secs(2)));

    Ok(())
}

fn produce_message<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<()> {
    let producer_data = types::input::ProduceMessageData::from_lua(LuaValue::Table(opts), lua)?;

    internal_producer(lua, producer_data)
}

async fn internal_create_topic(topic_data: CreateTopicData) -> LuaResult<()> {
    let mut config = ClientConfig::new();
    config.set("bootstrap.servers", topic_data.brokers.join(","));

    let client = kaf_unwrap!(AdminClient::from_config(&config));

    let new_topic = rdkafka::admin::NewTopic::new(
        topic_data.topic.as_str(),
        topic_data.num_partitions,
        rdkafka::admin::TopicReplication::Fixed(1),
    );

    let result = client
        .create_topics(&[new_topic], &AdminOptions::new())
        .await;
    kaf_unwrap!(result);
    Ok(())
}

async fn internal_delete_topic(topic_data: DeleteTopicData) -> LuaResult<()> {
    let mut config = ClientConfig::new();
    config.set("bootstrap.servers", topic_data.brokers.join(","));

    let client = kaf_unwrap!(AdminClient::from_config(&config));

    let result = client
        .delete_topics(&[topic_data.topic.as_str()], &AdminOptions::new())
        .await;
    kaf_unwrap!(result);
    Ok(())
}

fn create_topic<'a>(lua: &'a Lua, opts: mlua::Table<'a>) -> LuaResult<()> {
    let topic_data = CreateTopicData::from_lua(LuaValue::Table(opts), lua)?;

    futures::executor::block_on(internal_create_topic(topic_data))
}

fn delete_topic<'a>(lua: &'a Lua, opts: mlua::Table<'a>) -> LuaResult<()> {
    let topic_data = DeleteTopicData::from_lua(LuaValue::Table(opts), lua)?;

    futures::executor::block_on(internal_delete_topic(topic_data))
}

#[mlua::lua_module]
fn libkaf(lua: &Lua) -> LuaResult<LuaValue> {
    let exports = lua.create_table()?;

    exports.set("topics", lua.create_function(topics)?)?;
    exports.set("messages", lua.create_function(messages)?)?;
    exports.set("produce", lua.create_function(produce_message)?)?;
    exports.set("create_topic", lua.create_function(create_topic)?)?;
    exports.set("delete_topic", lua.create_function(delete_topic)?)?;

    Ok(LuaValue::Table(exports))
}
