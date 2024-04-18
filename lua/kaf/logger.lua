local M = {}

local lines = {}
local max_lines = 100

function M.log(...)
    local values = {}
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if type(item) == "table" then
            table.insert(values, vim.inspect(item))
        else
            table.insert(values, tostring(item))
        end
    end

    local processed_lines = {}
    for _, value in ipairs(values) do
        local split = vim.split(value, "\n")
        for _, line in ipairs(split) do
            table.insert(processed_lines, line)
        end
    end

    table.insert(lines, table.concat(processed_lines, " "))

    while #lines > max_lines do
        table.remove(lines, 1)
    end
end

function M.clear()
    lines = {}
end

function M.show()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_buf(0, bufnr)
end

return M
