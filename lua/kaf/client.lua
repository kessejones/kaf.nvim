local lib = require("kaf.artifact").load_lib("libkaf")
if lib == nil then
    error("libkaf.so not found")
end

---@class Topic
---@filed name string
---@filed partitions integer

local Client = {}
Client.__index = Client

---@param brokers string[]
---@return Client
function Client.new(name, brokers, selected_topic)
    return setmetatable({
        name = name,
        brokers = brokers,
        cache_topics = {},
        selected_topic = selected_topic,
        first_load = true,
    }, Client)
end

---@param force boolean
---@return Topic[]
function Client:topics(force)
    -- TODO: maybe we should check a timestamp of cache
    if self.first_load or force or #self.cache_topics == 0 then
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

---@return Topic|nil
function Client:current_topic()
    for _, topic in ipairs(self.cache_topics) do
        if topic.name == self.selected_topic then
            return topic
        end
    end
    return nil
end

---@return string[]
function Client:messages()
    if self.selected_topic == nil then
        -- TODO: add a better error handling
        error("any topic selected")
    end

    vim.cmd.doau("User KafFetchingMessages")

    local messages = lib.topic.messages({
        brokers = self.brokers,
        topic_name = self.selected_topic,
    })

    vim.cmd.doau("User KafFetchedMessages")
    return messages
end

---@param key string|nil
---@param value string
function Client:produce(key, value)
    if not self:current_topic() then
        -- TODO: add a better error handling
        error("any topic selected")
    end

    lib.topic.produce({
        brokers = self.brokers,
        topic_name = self:current_topic(),
        key = key,
        value = value,
    })
    vim.cmd.doau("User KafProducedMessage")
end

return Client
