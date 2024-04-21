pub mod result;
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

// replace kafka-rust for rdkafka
// https://docs.rs/rdkafka/0.36.2/rdkafka/

use futures::{self, executor};
use kafka::client::{FetchPartition, KafkaClient};
use kafka::producer::{Producer, Record};
use mlua::prelude::*;

use rdkafka::admin::AdminClient;
use rdkafka::config::FromClientConfig;

use crate::types::{Message, Topic};

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

    result::with_data(lua, topics)
}

fn messages<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaValue<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);
    let topic_name: String = opts.get("topic_name")?;

    let offset_value: i64 = match opts.get("offset_value") {
        Ok(offset_value) => offset_value,
        Err(_) => 10,
    };

    kaf_unwrap!(client.load_metadata_all());

    let offsets = kaf_unwrap!(
        client.fetch_topic_offsets(topic_name.as_str(), kafka::consumer::FetchOffset::Latest)
    );

    let reqs = offsets.iter().map(|offset| {
        FetchPartition::new(
            topic_name.as_str(),
            offset.partition,
            0.max(offset.offset - offset_value),
        )
    });

    let resps = kaf_unwrap!(client.fetch_messages(reqs));

    let mut messages = vec![];
    for resp in resps.iter() {
        for t in resp.topics() {
            for p in t.partitions() {
                let data = kaf_unwrap!(p.data());
                for message in data.messages() {
                    messages.push(Message {
                        key: match message.key.len() {
                            0 => None,
                            _ => Some(kaf_unwrap!(std::str::from_utf8(message.key)).to_owned()),
                        },
                        partition: p.partition().to_owned(),
                        offset: message.offset.to_owned(),
                        value: kaf_unwrap!(std::str::from_utf8(message.value)).to_owned(),
                    })
                }
            }
        }
    }

    result::with_data(lua, messages)
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

    executor::block_on(internal_create_topic(&topic_data))
}

fn delete_topic<'a>(lua: &'a Lua, opts: mlua::Table<'a>) -> LuaResult<()> {
    let topic_data = types::input::DeleteTopicData::from_lua(LuaValue::Table(opts), lua)?;

    executor::block_on(internal_delete_topic(&topic_data))
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
