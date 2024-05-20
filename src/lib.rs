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

use std::collections::HashMap;

use kafka::client::{FetchPartition, KafkaClient};
use kafka::producer::{Producer, Record};
use mlua::prelude::*;

use rdkafka::admin::AdminClient;
use rdkafka::config::FromClientConfig;
use rdkafka::consumer::ConsumerContext;
use rdkafka::statistics::TopicPartition;
use rdkafka::topic_partition_list::TopicPartitionListElem;
use rdkafka::util::Timeout;
use rdkafka::{ClientContext, Offset, TopicPartitionList};

use crate::types::output::Topic;
use crate::types::output::{vec_to_table, Message};

fn topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaValue<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);

    kaf_unwrap!(client.load_metadata_all());

    let mut topics = vec![];
    for topic in client.topics().iter() {
        topics.push(Topic {
            name: topic.name().to_string(),
            partitions: topic.partitions().len(),
        });
    }

    vec_to_table(lua, topics)
}

struct CustomConsumerContext;

impl ClientContext for CustomConsumerContext {}

impl ConsumerContext for CustomConsumerContext {
    fn pre_rebalance(&self, _rebalance: &rdkafka::consumer::Rebalance) {}
}

fn internal_messages<'a>(
    lua: &'a Lua,
    data: &types::input::MessageData,
) -> LuaResult<LuaValue<'a>> {
    use rdkafka::consumer::Consumer;

    let mut consumer_config = rdkafka::ClientConfig::new();
    consumer_config
        .set("bootstrap.servers", data.brokers.join(","))
        .set("enable.auto.commit", "false")
        .set("group.id", "kaf.nvim");

    let consumer_context = CustomConsumerContext;
    let consumer: rdkafka::consumer::BaseConsumer<_> =
        kaf_unwrap!(consumer_config.create_with_context(consumer_context));

    kaf_unwrap!(consumer.subscribe(&[data.topic.as_str()]));

    let metadata = kaf_unwrap!(consumer.fetch_metadata(
        Some(data.topic.as_str()),
        std::time::Duration::from_secs(10),
    ));

    let mut max_messages_partition = HashMap::new();

    let mut topic_partitions = TopicPartitionList::new();
    for metadata_topic in metadata.topics() {
        for partition in metadata_topic.partitions() {
            let (low, high) = kaf_unwrap!(consumer.fetch_watermarks(
                metadata_topic.name(),
                partition.id(),
                std::time::Duration::from_secs(10)
            ));

            let offset = if high - low > data.max_messages_per_partition {
                high - data.max_messages_per_partition
            } else {
                low
            };

            kaf_unwrap!(topic_partitions.add_partition_offset(
                metadata_topic.name(),
                partition.id(),
                Offset::Offset(offset),
            ));

            max_messages_partition.insert(partition.id(), 0);
        }
    }

    kaf_unwrap!(consumer.assign(&topic_partitions));
    let mut messages: Vec<crate::types::output::Message> = vec![];

    loop {
        match consumer.poll(std::time::Duration::from_secs(10)) {
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

                    messages.push(crate::types::output::Message {
                        key,
                        partition: rdkafka::Message::partition(&message),
                        timestamp,
                        offset: rdkafka::Message::offset(&message),
                        value: kaf_unwrap!(payload).to_owned(),
                    });

                    max_messages_partition
                        .get_mut(&rdkafka::Message::partition(&message))
                        .map(|x| *x += 1);

                    if !max_messages_partition
                        .iter()
                        .any(|(key, value)| *value < data.max_messages_per_partition)
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
    let message_data = types::input::MessageData::from_lua(LuaValue::Table(opts), lua)?;
    internal_messages(lua, &message_data)
}

fn produce_message<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<()> {
    let producer_data = types::input::ProducerData::from_lua(LuaValue::Table(opts), lua)?;

    let mut client = KafkaClient::new(producer_data.brokers);
    kaf_unwrap!(client.load_metadata_all());

    let mut producer = kaf_unwrap!(Producer::from_client(client).create());

    kaf_unwrap!(producer.send(&Record {
        topic: producer_data.topic.as_str(),
        partition: -1,
        key: match producer_data.key {
            Some(key) => key,
            None => "".to_owned(),
        },
        value: producer_data.value,
    }));

    Ok(())
}

async fn internal_create_topic(topic_data: &types::input::TopicData) -> LuaResult<()> {
    let mut config = rdkafka::config::ClientConfig::new();
    config.set("bootstrap.servers", topic_data.brokers.join(","));

    let client = kaf_unwrap!(AdminClient::from_config(&config));

    let new_topic = rdkafka::admin::NewTopic::new(
        topic_data.topic.as_str(),
        topic_data.num_partitions,
        rdkafka::admin::TopicReplication::Fixed(1),
    );

    let result = client
        .create_topics(&[new_topic], &rdkafka::admin::AdminOptions::new())
        .await;
    kaf_unwrap!(result);
    Ok(())
}

async fn internal_delete_topic(topic_data: &types::input::DeleteTopicData) -> LuaResult<()> {
    let mut config = rdkafka::config::ClientConfig::new();
    config.set("bootstrap.servers", topic_data.brokers.join(","));

    let client = kaf_unwrap!(AdminClient::from_config(&config));

    let result = client
        .delete_topics(
            &[topic_data.topic.as_str()],
            &rdkafka::admin::AdminOptions::new(),
        )
        .await;
    kaf_unwrap!(result);
    Ok(())
}

fn create_topic<'a>(lua: &'a Lua, opts: mlua::Table<'a>) -> LuaResult<()> {
    let topic_data = types::input::TopicData::from_lua(LuaValue::Table(opts), lua)?;

    futures::executor::block_on(internal_create_topic(&topic_data))
}

fn delete_topic<'a>(lua: &'a Lua, opts: mlua::Table<'a>) -> LuaResult<()> {
    let topic_data = types::input::DeleteTopicData::from_lua(LuaValue::Table(opts), lua)?;

    futures::executor::block_on(internal_delete_topic(&topic_data))
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
