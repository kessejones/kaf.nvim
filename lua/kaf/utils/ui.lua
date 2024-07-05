local M = {}

---@param message string
---@return boolean
function M.confirm(message, default)
    default = default or ""
    local input = string.lower(vim.fn.input(message))
    return input == default or input == "y" or input == "yes"
end

---@param prompt string
---@param default string?
---@return string|nil
function M.prompt(prompt, default)
    return vim.fn.input({ prompt = prompt, default = default })
end

return M
