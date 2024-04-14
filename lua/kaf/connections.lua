local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local cache_file = string.format("%s/kaf.json", data_path)

---@class Connection
---@field name string
---@field brokers table

local M = {}

---@type Connection[]
local cached_connections = {}

---@ptype string
local selected_connection = nil

---@return Connection[]
local function load_connections()
    local path_file = Path:new(cache_file)
    if not path_file:exists() then
        return {}
    end
    return vim.json.decode(Path:new(cache_file):read())
end

---@return Connection[]
function M.cache_connections(reload)
    if #cached_connections == 0 or reload then
        cached_connections = load_connections()
    end
    return cached_connections
end

---@return Connection|nil
local function create_connection_prompt()
    local name = vim.fn.input("Enter connection name: ")
    if name == "" then
        return nil
    end

    local con = M.connection_by_name(name)
    if con ~= nil then
        vim.print("Connection already exists")
        return nil
    end

    local brokers = vim.split(vim.fn.input("Enter broker list (separate by a colon): "), ",")
    if #brokers == 0 then
        return nil
    end

    return {
        name = name,
        brokers = brokers,
    }
end

function M.save_connections()
    local path_file = Path:new(cache_file)
    path_file:write(vim.json.encode(cached_connections), "w")
end

function M.create_connection()
    local new_con = create_connection_prompt()
    if new_con == nil then
        vim.print("Invalid connection")
        return
    end

    table.insert(cached_connections, new_con)
    M.save_connections()
end

---@param name string
---@return Connection|nil
function M.connection_by_name(name)
    for _, connection in ipairs(cached_connections) do
        if connection.name == name then
            return connection
        end
    end

    return nil
end

---@return Connection|nil
function M.selected_connection()
    if not selected_connection then
        return nil
    end
    return M.connection_by_name(selected_connection)
end

---@param name string
function M.select_connection(name)
    selected_connection = name
end

return M
