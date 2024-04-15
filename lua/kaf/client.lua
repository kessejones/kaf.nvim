local lib = require("kaf.artifact").load_lib("libkaf")
if lib == nil then
    error("libkaf.so not found")
end

local Client = {}
Client.__index = Client

---@param brokers string[]
---@return Client
function Client.new(name, brokers)
    return setmetatable({
        name = name,
        brokers = brokers,
        cache_topics = {},
        selcted_topic = nil,
        first_load = true,
    }, Client)
end

-- TODO: add metadata of topics on result
---@param force boolean
---@return string[]
function Client:topics(force)
    if self.first_load or force then
        self.cache_topics = lib.topic.topics({ brokers = self.brokers })
        self.first_load = false
    end
    return self.cache_topics
end

---@return string[]
function Client:cached_topics()
    return self.cache_topics
end

---@param name string
function Client:create_topic(name)
    return lib.create_topic({ brokers = self.brokers }, name)
end

---@param name string
function Client:delete_topic(name)
    return lib.delete_topic({ brokers = self.brokers }, name)
end

---@param name string
---@param count integer
---@return string[]
function Client:topic_messages(name, count)
    return lib.topic_messages({ brokers = self.brokers }, name, count)
end

---@param name string|nil
function Client:select_topic(name)
    self.selected_topic = name

    vim.cmd.doau("User KafTopicSelected")
end

---@return string|nil
function Client:current_topic()
    return self.selected_topic
end

return Client
