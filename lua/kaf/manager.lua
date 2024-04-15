local Manager = {}
Manager.__index = Manager

function Manager.new(clients, selected_client)
    clients = clients or {}

    local obj = setmetatable({
        clients = {},
        selected_client = nil,
    }, Manager)

    obj:add_clients(clients)
    obj.selected_client = selected_client

    return obj
end

---@param clients Client[]
function Manager:add_clients(clients)
    for _, client in ipairs(clients) do
        self:add_client(client)
    end
end

---@param client Client
function Manager:add_client(client)
    self.clients[client.name] = client
end

---@param name string
---@return Client|nil
function Manager:get_client(name)
    return self.clients[name]
end

---@param name string
function Manager:set_client(name)
    self.selected_client = name

    vim.cmd.doau("User KafClientSelected")
end

---@param name string
function Manager:remove_client(name)
    self.clients[name] = nil
end

---@return Client[]
function Manager:all_clients()
    local clients = {}
    for _, client in pairs(self.clients) do
        table.insert(clients, client)
    end
    return clients
end

---@return Client|nil
function Manager:current_client()
    return self.selected_client and self.clients[self.selected_client]
end

return Manager
