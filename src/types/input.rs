use mlua::prelude::LuaValue;
use mlua::prelude::*;
use mlua::Error;

use crate::kaf_unwrap;

pub struct ProducerData {
    pub brokers: Vec<String>,
    pub topic: String,
    pub key: Option<String>,
    pub value: String,
}

pub struct TopicData {
    pub brokers: Vec<String>,
    pub topic: String,
    pub num_partitions: i32,
}

pub struct DeleteTopicData {
    pub brokers: Vec<String>,
    pub topic: String,
}

impl FromLua<'_> for ProducerData {
    fn from_lua(value: LuaValue<'_>, _lua: &'_ Lua) -> LuaResult<Self> {
        let table = match value.as_table() {
            Some(table) => table,
            None => return Err(Error::RuntimeError("Invalid table".to_string())),
        };

        let key = match table.get("key") {
            Ok(LuaValue::String(key)) => Some(key.to_str()?.to_owned()),
            _ => None,
        };

        let topic = table.get("topic")?;
        let value = table.get("value")?;
        let brokers = table.get("brokers")?;

        Ok(ProducerData {
            brokers,
            topic,
            key,
            value,
        })
    }
}

impl FromLua<'_> for TopicData {
    fn from_lua(value: LuaValue<'_>, _lua: &'_ Lua) -> LuaResult<Self> {
        let table = match value.as_table() {
            Some(table) => table,
            None => return Err(Error::RuntimeError("Invalid table".to_string())),
        };

        let brokers = table.get("brokers")?;
        let topic = table.get("topic")?;
        let num_partitions = table.get("num_partitions")?;

        Ok(Self {
            brokers,
            topic,
            num_partitions,
        })
    }
}

impl FromLua<'_> for DeleteTopicData {
    fn from_lua(value: LuaValue<'_>, _lua: &'_ Lua) -> LuaResult<Self> {
        let table = match value.as_table() {
            Some(table) => table,
            None => return Err(Error::RuntimeError("Invalid table".to_string())),
        };

        let brokers = table.get("brokers")?;
        let topic = table.get("topic")?;

        Ok(Self { brokers, topic })
    }
}
