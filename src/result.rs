use mlua::prelude::*;

use crate::types::{self, KafData};

pub fn with_data<'a, T>(lua: &'a Lua, data: T) -> LuaResult<LuaValue<'a>>
where
    T: IntoLua<'a>,
{
    KafData { data }.into_lua(lua)
}

pub fn with_error<'a>(lua: &'a Lua, msg: String) -> LuaResult<LuaValue<'a>> {
    let e = types::KafError { error: msg };
    e.into_lua(lua)
}
