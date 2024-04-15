use kafka::client::{FetchPartition, KafkaClient};
use mlua::prelude::*;
use mlua::Error;

fn topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaTable<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);
    client.load_metadata_all().unwrap();

    let table_topics = lua.create_table()?;
    let mut index = 1;
    for topic in client.topics().iter() {
        let topic_name = lua.create_string(topic.name())?;
        table_topics.set(index, topic_name)?;

        index += 1;
    }

    Ok(table_topics)
}

fn topic_messages<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaTable<'a>> {
    let mut client = KafkaClient::new(opts.get("brokers")?);
    let topic_name: String = opts.get("topic_name")?;

    // let max_bytes: i32 = match opts.get("max_bytes") {
    //     Ok(max_bytes) => max_bytes,
    //     Err(_) => 1024 * 1024,
    // };

    // let offset_value: i64 = match opts.get("offset_value") {
    //     Ok(offset_value) => offset_value,
    //     Err(_) => 10,
    // };

    client.load_metadata_all().unwrap();

    let offsets = client
        .fetch_topic_offsets(topic_name.as_str(), kafka::consumer::FetchOffset::Latest)
        .unwrap();

    let reqs = offsets
        .iter()
        .map(|offset| FetchPartition::new(topic_name.as_str(), offset.partition, offset.offset));

    let resps = client.fetch_messages(reqs).unwrap();

    let messages_table = lua.create_table()?;
    let mut index = 1;
    for resp in resps.iter() {
        for t in resp.topics() {
            for p in t.partitions() {
                match p.data() {
                    Err(_) => return Err(Error::RuntimeError("error on read kafka".to_string())),
                    Ok(ref data) => {
                        for message in data.messages() {
                            let message_data = lua.create_table()?;
                            message_data.set("key", lua.create_string(message.key)?)?;
                            message_data.set("offset", message.offset)?;
                            message_data.set("value", lua.create_string(message.value)?)?;
                            message_data.set("partition", p.partition())?;

                            messages_table.set(index, message_data)?;

                            index += 1;
                        }
                    }
                }
            }
        }
    }

    Ok(messages_table)
}

// fn create_topic<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<()> {
//     let mut client = KafkaClient::new(opts.get("brokers")?);
//     let topic_name = KafkaClient::new(opts.get("topic_name")?);
//     client.load_metadata_all().unwrap();
//
//     Ok(())
// }

pub fn topic<'a>(lua: &'a Lua) -> LuaResult<LuaTable<'a>> {
    let exports = lua.create_table()?;

    exports.set("topics", lua.create_function(topics)?)?;
    // exports.set("create_topic", lua.create_function(create_topic)?)?;
    exports.set("messages", lua.create_function(topic_messages)?)?;

    return Ok(exports);
}
