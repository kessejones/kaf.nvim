local M = {}

function M.find_lib_path()
    -- local artifact_file = require("plenary.debug_utils").sourced_filepath()
    -- local kaf_path = vim.fn.fnamemodify(artifact_file, ":p:h:h:h:h")
    -- return kaf_path .. "/target/debug/"
    return "/Users/kesse.coaioto/src/kaf.nvim/target/debug/"
end

function M.load_external_lib(libname)

    -- local lib_path = find_lib_path() .. libname .. ".dylib"
    -- local dll = package.loadlib(lib_path, "luaopen_" .. libname)
    -- if dll then
    --     local loaded = dll()
    --     loaded._library_path = lib_path
    --     return loaded
    -- end
end

return M
