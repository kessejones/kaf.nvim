use mlua::prelude::LuaValue;
use mlua::prelude::*;
use mlua::Error;

#[derive(Debug, Clone)]
pub struct Topic {
    pub name: String,
    pub partitions: usize,
}

#[derive(Debug, Clone)]
pub struct Message {
    pub key: Option<String>,
    pub partition: i32,
    pub offset: i64,
    pub value: String,
}

impl IntoLua<'_> for Message {
    fn into_lua<'lua>(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        let table = lua.create_table()?;

        let key = match self.key {
            Some(key) => {
                let key = lua.create_string(key.as_str())?;
                LuaValue::String(key)
            }
            None => LuaValue::Nil,
        };

        let value = lua.create_string(self.value.as_str())?;

        table.set("key", key)?;
        table.set("offset", self.offset)?;
        table.set("partition", self.partition)?;
        table.set("value", value)?;

        Ok(LuaValue::Table(table))
    }
}

impl IntoLua<'_> for Topic {
    fn into_lua<'lua>(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        let table = lua.create_table()?;

        let name = lua.create_string(self.name.as_str())?;

        table.set("name", name)?;
        table.set("partitions", self.partitions)?;

        Ok(LuaValue::Table(table))
    }
}

pub struct ProducePayload {
    pub brokers: Vec<String>,
    pub topic: String,
    pub key: Option<String>,
    pub value: String,
}

impl FromLua<'_> for ProducePayload {
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

        Ok(ProducePayload {
            brokers,
            topic,
            key,
            value,
        })
    }
}

pub struct KafData<T> {
    pub data: T,
}

impl<'a, T: IntoLua<'a>> IntoLua<'a> for KafData<T> {
    fn into_lua(self, lua: &'a Lua) -> LuaResult<LuaValue<'a>> {
        let table = lua.create_table()?;

        let data = self.data.into_lua(lua)?;
        table.set("data", data)?;
        table.set("has_error", false)?;

        Ok(LuaValue::Table(table))
    }
}

pub struct KafError {
    pub error: String,
}

impl<'a> IntoLua<'a> for KafError {
    fn into_lua(self, lua: &'a Lua) -> LuaResult<LuaValue<'a>> {
        let table = lua.create_table()?;

        let error = lua.create_string(self.error.as_str())?;
        table.set("error", error)?;
        table.set("has_error", true)?;

        Ok(LuaValue::Table(table))
    }
}
