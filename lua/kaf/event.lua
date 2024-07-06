local M = {}

---@enum EventType
M.type = {
    CLIENT_SELECTED = "CLIENT_SELECTED",
    CLIENT_CREATED = "CLIENT_CREATED",
    TOPIC_SELECTED = "TOPIC_SELECTED",
    TOPIC_CREATED = "TOPIC_CREATED",
    TOPIC_DELETED = "TOPIC_DELETED",
    CLIENT_REMOVED = "CLIENT_REMOVED",
    MESSAGES_FETCHING = "MESSAGES_FETCHING",
    MESSAGES_FETCHED = "MESSAGES_FETCHED",
    MESSAGE_PRODUCED = "MESSAGE_PRODUCED",
    TOPICS_FETCHED = "TOPICS_FETCHED",
}

---@param type EventType
---@param data table?
function M.emit(type, data)
    vim.api.nvim_exec_autocmds("User", { pattern = type, modeline = false, data = data or {} })
end

---@param pattern EventType|table<EventType>
---@param callback fun(e: table)
function M.on(pattern, callback)
    vim.api.nvim_create_autocmd("User", {
        pattern = pattern,
        callback = vim.schedule_wrap(function(e)
            callback(e)
        end),
    })
end

return M
