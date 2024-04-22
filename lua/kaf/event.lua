local M = {}

---@param type string
---@param data table?
function M.emit(type, data)
    vim.api.nvim_exec_autocmds("User", { pattern = type, modeline = false, data = data or {} })
end

---@param pattern string|table<number, string>
function M.on(pattern, callback)
    vim.api.nvim_create_autocmd("User", {
        pattern = pattern,
        callback = callback,
    })
end

return M
