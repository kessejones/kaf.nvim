local M = {}

---@class Topic
---@field public name string
---@field public partitions integer

---@class Message
---@field public key string?
---@field public partition integer
---@field public offset integer
---@field public value string
--
---@class CacheData
---@field public clients Client[]
---@field public selected_client string?

---@class Notification
---@field public title string?
---@field public message string
---@field public percentage integer?

---@class ProduceOpts
---@field public key string?
---@field public prompt_key boolean
---@field public value string?
---@field public value_from_buffer boolean

--TODO: Add the enum EventType
M.EventType = {
    ClientSelected = "ClientSelected",
    ClientCreated = "ClientCreated",
    TopicSelected = "TopicSelected",
    TopicCreated = "TopicCreated",
    TopicDeleted = "TopicDeleted",
    ClientRemoved = "ClientRemoved",
    MessagesFetching = "MessagesFetching",
    MessagesFetched = "MessagesFetched",
    MessageProduced = "MessageProduced",
    TopicsFetched = "TopicsFetched",
}

return M
