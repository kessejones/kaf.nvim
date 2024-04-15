local Event = {}

---@enum EventType
---| 'KafSelected'

---@param type EventType
function Event.emit(type, args) end

return Event
