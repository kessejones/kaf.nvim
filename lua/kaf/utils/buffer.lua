local M = {}

---@param bufnr number?
---@return string
function M.get_buffer_content(bufnr)
    bufnr = bufnr or 0
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "")
end

return M
