local timestamps = require("kaf.utils.timestamps")

-- TODO: use a config value instead of a hardcoded value
local VALID_CACHE_MINUTES = 60

---@class CacheTopic
---@field public topics Topic[]
---@field public timestamp integer
local CacheTopic = {}
CacheTopic.__index = CacheTopic

---@param topics Topic[]
function CacheTopic.new(topics)
    return setmetatable({
        topics = topics,
        timestamp = timestamps.now(),
    }, CacheTopic)
end

---@param topics Topic[]
function CacheTopic:set_topics(topics)
    self.topics = topics
    self.timestamp = timestamps.now()
end

---@return boolean
function CacheTopic:empty()
    return #self.topics == 0
end

---@return boolean
function CacheTopic:valid()
    if self:empty() then
        return false
    end

    return timestamps.diff_in_minutes(self.timestamp, timestamps.now()) <= VALID_CACHE_MINUTES
end

return CacheTopic
