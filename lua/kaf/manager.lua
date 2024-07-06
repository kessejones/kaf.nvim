local Client = require("kaf.client")
local event = require("kaf.event")
local notifier = require("kaf.notifier")

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
function Manager.add_clients(clients)
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

    event.emit(event.type.CLIENT_SELECTED, Manager.current_client())
end

---@param name string
function Manager.remove_client(name)
    local client = _clients[name]
    if client then
        _clients[name] = nil

        if _selected_client == name then
            _selected_client = nil
        end

        event.emit(event.type.CLIENT_REMOVED, client)
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
    event.emit(event.type.CLIENT_CREATED)

    return client
end

---@return Topic[]
function Manager.topics(force)
    local client = Manager.current_client()
    if not client then
        notifier.notify("Client not selected")
        return {}
    end

    event.emit(event.type.FetchingTopics)
    local topics = client:topics(force)
    event.emit(event.type.TOPICS_FETCHED, { forced = force })
    return topics
end

---@return Message[]
function Manager.messages()
    local client = Manager.current_client()
    if not client then
        notifier.notify("Client not selected")
        return {}
    end

    event.emit(event.type.MESSAGES_FETCHING)
    local messages = client:messages()
    event.emit(event.type.MESSAGES_FETCHED)

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
    event.emit(event.type.TOPIC_SELECTED)
end

---@param topic_name string
---@param num_partitions integer
function Manager.create_topic(topic_name, num_partitions)
    local client = Manager.current_client()
    if not client then
        notifier.notify("Client not selected")
        return {}
    end

    if client:create_topic(topic_name, num_partitions) then
        event.emit(event.type.TOPIC_CREATED)
    end
end

---@param topic_name string
function Manager.delete_topic(topic_name)
    local client = Manager.current_client()
    if not client then
        notifier.notify("Client not selected")
        return {}
    end

    if client:delete_topic(topic_name) then
        event.emit(event.type.TOPIC_DELETED)
    end
end

---@param key string?
---@param value string
function Manager.produce_message(key, value)
    local client = Manager.current_client()
    if not client then
        notifier.notify("Client not selected")
        return {}
    end

    client:produce(key, value)
    event.emit(event.type.MESSAGE_PRODUCED)
end

return Manager
