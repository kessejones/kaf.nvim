use mlua::prelude::LuaValue;
use mlua::prelude::*;
use mlua::Error;

pub struct ListTopicsData {
    pub brokers: Vec<String>,
}

pub struct ProduceMessageData {
    pub brokers: Vec<String>,
    pub topic: String,
    pub key: Option<String>,
    pub value: String,
}

pub struct CreateTopicData {
    pub brokers: Vec<String>,
    pub topic: String,
    pub num_partitions: i32,
}

pub struct DeleteTopicData {
    pub brokers: Vec<String>,
    pub topic: String,
}

pub struct ListMessagesData {
    pub brokers: Vec<String>,
    pub topic: String,
    pub max_messages_per_partition: i64,
}

impl FromLua<'_> for ListTopicsData {
    fn from_lua(value: LuaValue<'_>, _lua: &'_ Lua) -> LuaResult<Self> {
        let table = match value.as_table() {
            Some(table) => table,
            None => return Err(Error::RuntimeError("Invalid table".to_string())),
        };

        let brokers = table.get("brokers")?;

        Ok(Self { brokers })
    }
}

impl FromLua<'_> for ProduceMessageData {
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

        Ok(ProduceMessageData {
            brokers,
            topic,
            key,
            value,
        })
    }
}

impl FromLua<'_> for CreateTopicData {
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
impl FromLua<'_> for ListMessagesData {
    fn from_lua(value: LuaValue<'_>, _lua: &'_ Lua) -> LuaResult<Self> {
        let table = match value.as_table() {
            Some(table) => table,
            None => return Err(Error::RuntimeError("Invalid table".to_string())),
        };

        let brokers = table.get("brokers")?;
        let topic = table.get("topic")?;

        let max_messages_per_partition: i64 = match table.get("max_messages_per_partition") {
            Ok(offset) => offset,
            Err(_) => 10,
        };

        Ok(Self {
            brokers,
            topic,
            max_messages_per_partition,
        })
    }
}
