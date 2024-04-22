local logger = require("kaf.logger")
local notify = require("kaf.notify")
local lib = require("kaf.artifact").load_lib("libkaf")
if lib == nil then
    error("libkaf.so not found")
end

---@class Client
---@field private name string
---@field private brokers string[]
---@field private cache_topics Topic[]
---@field private selected_topic string?
---@field private first_load boolean
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
        local ok, data = pcall(lib.topics, { brokers = self.brokers })
        if not ok then
            notify.notify(data)
            return {}
        end
        self.cache_topics = data
        self.first_load = false
    end
    return self.cache_topics
end

---@param brokers string[]
function Client:set_brokers(brokers)
    self.brokers = brokers
end

---@return string[]
function Client:cached_topics()
    return self.cache_topics
end

---@param name string
function Client:create_topic(name, num_partitions)
    vim.print(name, num_partitions)
    local ok, data = pcall(lib.create_topic, { brokers = self.brokers, topic = name, num_partitions = num_partitions })
    notify.notify(data)

    return ok
end

---@param name string
function Client:delete_topic(name)
    local ok, data = pcall(lib.delete_topic, { brokers = self.brokers, topic = name })

    if ok then
        for i, topic in ipairs(self.cache_topics) do
            if topic.name == name then
                table.remove(self.cache_topics, i)
                break
            end
        end
    end

    notify.notify(data)

    return ok
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

---@return Message[]
function Client:messages()
    if self.selected_topic == nil then
        notify.notify("No topic selected")
        return {}
    end

    vim.cmd.doau("User KafFetchingMessages")

    local ok, data = pcall(lib.messages, {
        brokers = self.brokers,
        topic = self.selected_topic,
    })

    if not ok then
        notify.notify(data)
    end

    vim.cmd.doau("User KafFetchedMessages")

    return data
end

---@param key string|nil
---@param value string
function Client:produce(key, value)
    if self.selected_topic == nil then
        notify.notify("No topic selected")
        return {}
    end

    local ok, data = pcall(lib.produce, {
        brokers = self.brokers,
        topic = self.selected_topic,
        key = key,
        value = value,
    })

    if not ok then
        notify.notify(data)
    end

    vim.cmd.doau("User KafProducedMessage")
end

return Client
