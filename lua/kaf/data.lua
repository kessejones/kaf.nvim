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
    for _, item in ipairs(data) do
        table.insert(clients, Client.new(item.name, item.brokers))
    end
    return clients
end

---@param clients Client[]
function Data.save_cache_file(clients)
    local path_file = Path:new(cache_file)
    path_file:write(vim.json.encode(clients), "w")
end

return Data
