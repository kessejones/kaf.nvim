local M = {}

---@param message string
---@return boolean
function M.confirm(message)
    local input = vim.fn.input(message)
    return input == "" or input == "y" or input == "yes"
end

---@param prompt string
---@param default string?
---@return string|nil
function M.prompt(prompt, default)
    return vim.fn.input({ prompt = prompt, default = default })
end

return M
