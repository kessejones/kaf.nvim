local M = {}

local uv = vim.uv

local artifact_file = require("plenary.debug_utils").sourced_filepath()
local kaf_root = vim.fn.fnamemodify(artifact_file, ":p:h:h:h")

local sort_by_time = function(candidates)
    table.sort(candidates, function(a, b)
        return a.stat.mtime.sec > b.stat.mtime.sec
    end)
end

function M.load_lib(name)
    local ok, lib = pcall(require, name)
    if ok then
        return lib
    end

    local libname = "luaopen_" .. name
    local candidates = {}
    local directories = { "/target/debug/", "/target/release/", "/lib/" }
    local suffixes = { ".so", ".dylib" }
    for _, dir in ipairs(directories) do
        for _, suffix in ipairs(suffixes) do
            local path = kaf_root .. dir .. name .. suffix
            local stat = uv.fs_stat(path)
            if stat then
                table.insert(candidates, { stat = stat, path = path })
            end
        end
    end

    sort_by_time(candidates)
    for _, candidate in ipairs(candidates) do
        local dll = package.loadlib(candidate.path, libname)
        if dll then
            local loaded = dll()
            loaded._library_path = candidate.path
            return loaded
        end
    end
end

return M
