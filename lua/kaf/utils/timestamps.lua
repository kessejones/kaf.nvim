local M = {}

function M.now()
    return vim.fn.localtime()
end

---@param first integer
---@param second integer
function M.diff_in_minutes(first, second)
    return (second - first) / 60
end

return M
