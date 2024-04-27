local Client = require("kaf.client")
local event = require("kaf.event")
local notify = require("kaf.notify")
local EventType = require("kaf.types").EventType

---@class Manager
---@field private clients table<string, Client>
local Manager = {}
Manager.__index = Manager

local _clients = {}
local _selected_client = nil

---@param clients Client[]
---@param selected_client string?
function Manager.setup(clients, selected_client)
    _clients = {}
    Manager.add_clients(clients)
    _selected_client = selected_client
end

---@param clients Client[]
function Manager.add_clients(clients, internal)
    for _, client in ipairs(clients) do
        Manager.add_client(client)
    end
end

---@param client Client
function Manager.add_client(client)
    _clients[client.name] = client
end

---@param name string
---@return Client|nil
function Manager.get_client(name)
    return _clients[name]
end

---@param name string
function Manager.set_client(name)
    _selected_client = name

    event.emit(EventType.ClientSelected, Manager.current_client())
end

---@param name string
function Manager.remove_client(name)
    local client = _clients[name]
    if client then
        _clients[name] = nil

        if _selected_client == name then
            _selected_client = nil
        end

        event.emit(EventType.ClientRemoved, client)
    end
end

---@return Client[]
function Manager.all_clients()
    local clients = {}
    for _, client in pairs(_clients) do
        table.insert(clients, client)
    end
    return clients
end

---@return string|nil
function Manager.selected_client()
    return _selected_client
end

---@return Client|nil
function Manager.current_client()
    return _selected_client and _clients[_selected_client]
end

---@param name string
---@param brokers string[]
---@return Client|nil
function Manager.create_client(name, brokers)
    local client = Client.new(name, brokers)
    Manager.add_client(client)
    event.emit(EventType.ClientCreated)

    return client
end

---@return Topic[]
function Manager.topics(force)
    local client = Manager.current_client()
    if not client then
        notify.notify("Client not selected")
        return {}
    end

    event.emit(EventType.FetchingTopics)
    local topics = client:topics(force)
    event.emit(EventType.TopicsFetched, { forced = force })
    return topics
end

---@return Message[]
function Manager.messages()
    local client = Manager.current_client()
    if not client then
        vim.notify("Client not selected")
        return {}
    end

    event.emit(EventType.MessagesFetching)
    local messages = client:messages()
    event.emit(EventType.MessagesFetched)

    return messages
end

---@param topic_name string
function Manager.select_topic(topic_name)
    local client = Manager.current_client()
    if not client then
        vim.notify("Client not selected")
        return {}
    end

    client:select_topic(topic_name)
    event.emit(EventType.TopicSelected)
end

---@param topic_name string
---@param num_partitions integer
function Manager.create_topic(topic_name, num_partitions)
    local client = Manager.current_client()
    if not client then
        vim.notify("Client not selected")
        return {}
    end

    if client:create_topic(topic_name, num_partitions) then
        event.emit(EventType.TopicCreated)
    end
end

---@param topic_name string
function Manager.delete_topic(topic_name)
    local client = Manager.current_client()
    if not client then
        notify.notify("Client not selected")
        return {}
    end

    if client:delete_topic(topic_name) then
        event.emit(EventType.TopicDeleted)
    end
end

---@param key string?
---@param value string
function Manager.produce_message(key, value)
    local client = Manager.current_client()
    if not client then
        notify.notify("Client not selected")
        return {}
    end

    client:produce(key, value)
    event.emit(EventType.MessageProduced)
end

return Manager
