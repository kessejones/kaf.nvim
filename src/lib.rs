mod result;
mod types;

extern crate mlua;

// replace kafka-rust for rdkafka
// https://docs.rs/rdkafka/0.36.2/rdkafka/

use kafka::client::{FetchPartition, KafkaClient};
use kafka::producer::{Producer, Record};
use mlua::prelude::*;

use crate::types::{Message, Topic};

fn topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaValue<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);

    match client.load_metadata_all() {
        Ok(_) => (),
        Err(e) => return result::with_error(lua, format!("{}", e)),
    }

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

    match client.load_metadata_all() {
        Ok(_) => (),
        Err(e) => return result::with_error(lua, e.to_string()),
    }

    let offsets = match client
        .fetch_topic_offsets(topic_name.as_str(), kafka::consumer::FetchOffset::Latest)
    {
        Ok(offsets) => offsets,
        Err(e) => return result::with_error(lua, e.to_string()),
    };

    let reqs = offsets.iter().map(|offset| {
        FetchPartition::new(
            topic_name.as_str(),
            offset.partition,
            0.max(offset.offset - offset_value),
        )
    });

    let resps = match client.fetch_messages(reqs) {
        Ok(resps) => resps,
        Err(e) => return result::with_error(lua, e.to_string()),
    };

    let mut messages = vec![];
    for resp in resps.iter() {
        for t in resp.topics() {
            for p in t.partitions() {
                match p.data() {
                    Err(e) => return result::with_error(lua, e.to_string()),
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

    result::with_data(lua, messages)
}

fn produce_message<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<()> {
    let payload = types::ProducePayload::from_lua(LuaValue::Table(opts), lua)?;

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
fn libkaf(lua: &Lua) -> LuaResult<LuaValue> {
    let exports = lua.create_table()?;

    exports.set("topics", lua.create_function(topics)?)?;
    exports.set("messages", lua.create_function(messages)?)?;
    exports.set("produce", lua.create_function(produce_message)?)?;

    Ok(LuaValue::Table(exports))
}
