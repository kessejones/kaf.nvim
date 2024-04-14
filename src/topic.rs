use kafka::client::KafkaClient;
use mlua::prelude::*;

fn get_topics<'a>(lua: &'a Lua, opts: mlua::Table) -> LuaResult<LuaTable<'a>> {
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

pub fn topic<'a>(lua: &'a Lua) -> LuaResult<LuaTable<'a>> {
    let exports = lua.create_table()?;

    exports.set("get_topics", lua.create_function(get_topics)?)?;

    return Ok(exports);
}
