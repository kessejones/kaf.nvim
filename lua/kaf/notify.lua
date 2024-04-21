---@class Notify
local M = {}

function M.notify(data)
    if type(data) ~= "string" then
        data = tostring(data)
    end
    vim.notify(data)
end

return M
