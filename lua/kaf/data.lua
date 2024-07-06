---@class CacheData
---@field public clients Client[]
---@field public selected_client string?

local Client = require("kaf.client")
local Path = require("plenary.path")
local manager = require("kaf.manager")

local data_path = vim.fn.stdpath("data")
local cache_file = string.format("%s/kaf.json", data_path)

local M = {}

---@return CacheData
function M.load_cache_file()
    local path_file = Path:new(cache_file)
    if not path_file:exists() then
        return { clients = {}, selected_client = nil }
    end

    local data = vim.json.decode(Path:new(cache_file):read())
    local clients = {}
    for _, item in ipairs(data.clients) do
        table.insert(clients, Client.new(item.name, item.brokers, item.selected_topic, item.cache_topics))
    end

    return { clients = clients, selected_client = data.selected_client }
end

---@param selected_client string|nil
---@param clients Client[]
function M.save_cache_file(selected_client, clients)
    local path_file = Path:new(cache_file)

    path_file:write(vim.json.encode({ clients = clients, selected_client = selected_client }), "w")
end

function M.save_cache()
    M.save_cache_file(manager.selected_client(), manager.all_clients())
end

function M.delete_cache()
    local path_file = Path:new(cache_file)
    if path_file:exists() then
        path_file:rm()
    end
end

return M
