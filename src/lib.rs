mod types;

extern crate mlua;

use kafka::client::{FetchPartition, KafkaClient};
use kafka::producer::{Producer, Record};
use mlua::prelude::*;
use mlua::Error;

use crate::types::{Message, Topic};

fn topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaTable<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);
    client.load_metadata_all().unwrap();

    let mut topics = vec![];
    for topic in client.topics().iter() {
        topics.push(Topic {
            name: topic.name().to_string(),
            partitions: topic.partitions().len(),
        });
    }

    Ok(types::vec_to_table(lua, topics)?)
}

fn messages<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaTable<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);
    let topic_name: String = opts.get("topic_name")?;

    // let max_bytes: i32 = match opts.get("max_bytes") {
    //     Ok(max_bytes) => max_bytes,
    //     Err(_) => 1024 * 1024,
    // };

    let offset_value: i64 = match opts.get("offset_value") {
        Ok(offset_value) => offset_value,
        Err(_) => 10,
    };

    client.load_metadata_all().unwrap();

    let offsets = client
        .fetch_topic_offsets(topic_name.as_str(), kafka::consumer::FetchOffset::Latest)
        .unwrap();

    let reqs = offsets.iter().map(|offset| {
        FetchPartition::new(
            topic_name.as_str(),
            offset.partition,
            0.max(offset.offset - offset_value),
        )
    });

    let resps = client.fetch_messages(reqs).unwrap();

    let mut messages = vec![];
    for resp in resps.iter() {
        for t in resp.topics() {
            for p in t.partitions() {
                match p.data() {
                    Err(_) => return Err(Error::RuntimeError("error on read kafka".to_string())),
                    Ok(ref data) => {
                        for message in data.messages() {
                            messages.push(Message {
                                key: match message.key.len() {
                                    0 => None,
                                    _ => Some(std::str::from_utf8(message.key).unwrap().to_owned()),
                                },
                                partition: p.partition().to_owned(),
                                offset: message.offset.to_owned(),
                                value: std::str::from_utf8(message.value).unwrap().to_owned(),
                            })
                        }
                    }
                }
            }
        }
    }

    Ok(types::vec_to_table(lua, messages)?)
}

fn produce_message<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<()> {
    let payload = types::ProducePayload::from_lua(LuaValue::Table(opts), lua)?;
    // let value: String = opts.get("value")?;
    // let brokers: Vec<String> = opts.get("brokers")?;
    // let topic_name: String = opts.get("topic_name")?;
    // let key: String = match opts.get("key") {
    //     Ok(key) => key,
    //     Err(_) => "".to_owned(),
    // };
    //
    let mut client = KafkaClient::new(payload.brokers);
    client.load_metadata_all().unwrap();

    let mut producer = Producer::from_client(client).create().unwrap();
    producer
        .send(&Record {
            topic: payload.topic.as_str(),
            partition: -1,
            key: match payload.key {
                Some(key) => key,
                None => "".to_owned(),
            },
            value: payload.value,
        })
        .unwrap();

    Ok(())
}

#[mlua::lua_module]
fn libkaf(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    exports.set("topics", lua.create_function(topics)?)?;
    exports.set("messages", lua.create_function(messages)?)?;
    exports.set("produce", lua.create_function(produce_message)?)?;
    Ok(exports)
}
