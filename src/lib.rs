mod topic;

extern crate mlua;

use mlua::prelude::*;

#[mlua::lua_module]
fn libkaf(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    // exports.set("get_topics", lua.create_function(topics::get_topics)?)?;
    exports.set("topic", topic::topic(lua)?)?;
    Ok(exports)
}
