local Client = require("kaf.client")
local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local cache_file = string.format("%s/kaf.json", data_path)

local Data = {}

---@return Client[]
function Data.load_cache_file()
    local path_file = Path:new(cache_file)
    if not path_file:exists() then
        return {}
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
function Data.save_cache_file(selected_client, clients)
    local path_file = Path:new(cache_file)

    path_file:write(vim.json.encode({ clients = clients, selected_client = selected_client }), "w")
end

return Data
