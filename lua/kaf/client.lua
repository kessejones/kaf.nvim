local notifier = require("kaf.notifier")
local CacheTopic = require("kaf.cache")

---@class Client
---@field public name string
---@field public brokers string[]
---@field public selected_topic string?
---@field private cache CacheTopic
local Client = {}
Client.__index = Client

---@param name string
---@param brokers string[]
---@param selected_topic string?
---@param topics Topic[]
---@return Client
function Client.new(name, brokers, selected_topic, topics)
    return setmetatable({
        name = name,
        brokers = brokers,
        selected_topic = selected_topic,
        cache = CacheTopic.new(topics or {}),
    }, Client)
end

---@param force boolean
---@return Topic[]
function Client:topics(force)
    if force or not self.cache:valid() then
        local ok, data = pcall(vim.fn.KafTopics, { brokers = self.brokers })
        if not ok then
            notifier.notify(data)
            return {}
        end
        self.cache:set_topics(data)

        vim.notify("update cache")
    end

    vim.notify("topics")
    return self.cache.topics
end

---@param brokers string[]
function Client:set_brokers(brokers)
    self.brokers = brokers
end

---@param name string
function Client:create_topic(name, num_partitions)
    local ok, data = pcall(vim.fn.KafCreateTopic, { brokers = self.brokers, topic = name, partitions = num_partitions })

    if not ok then
        notifier.notify(data)
    end

    return ok
end

---@param name string
function Client:delete_topic(name)
    local ok, data = pcall(vim.fn.KafDeleteTopic, { brokers = self.brokers, topic = name })

    if ok then
        for i, topic in ipairs(self.cache.topics) do
            if topic.name == name then
                table.remove(self.cache.topics, i)
                break
            end
        end
    else
        notifier.notify(data)
    end

    return ok
end

---@param name string|nil
function Client:select_topic(name)
    self.selected_topic = name
end

---@return Topic|nil
function Client:current_topic()
    for _, topic in ipairs(self.cache.topics) do
        if topic.name == self.selected_topic then
            return topic
        end
    end
    return nil
end

---@return Message[]
function Client:messages()
    if self.selected_topic == nil then
        notifier.notify("No topic selected")
        return {}
    end

    local ok, data = pcall(vim.fn.KafMessages, {
        brokers = self.brokers,
        topic = self.selected_topic,
        -- max_messages_per_partition = config.data().kafka.max_messages_per_partition,
    })

    if not ok then
        notifier.notify(data)
    end

    return data
end

---@param key string|nil
---@param value string
function Client:produce(key, value)
    if self.selected_topic == nil then
        notifier.notify("No topic selected")
        return {}
    end

    local ok, data = pcall(vim.fn.KafProduce, {
        brokers = self.brokers,
        topic = self.selected_topic,
        key = key,
        value = value,
    })

    if not ok then
        notifier.notify(data)
    end
end

return Client
