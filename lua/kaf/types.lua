local M = {}

---@class Topic
---@field public name string
---@field public partitions integer

---@class Message
---@field public key string?
---@field public partition integer
---@field public offset integer
---@field public value string

--TODO: Add the enum EventType
M.EventType = {
    ClientSelected = "ClientSelected",
    TopicSelected = "TopicSelected",
    ClientRemoved = "ClientRemoved",
    FetchingMessages = "FetchingMessages",
    FetchedMessages = "FetchedMessages",
    ProducedMessage = "ProducedMessage",
    FetchedTopics = "FetchedTopics",
}

return M
