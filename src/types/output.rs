use mlua::prelude::*;

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

pub fn vec_to_table<'a, T>(lua: &'a mlua::Lua, list: Vec<T>) -> LuaResult<LuaValue<'a>>
where
    T: IntoLua<'a> + Clone,
{
    let table = lua.create_table()?;

    let mut index = 1;
    for item in list.iter() {
        table.set(index, item.clone().into_lua(lua)?)?;
        index += 1;
    }

    Ok(LuaValue::Table(table))
}
