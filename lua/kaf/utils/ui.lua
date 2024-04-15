local M = {}

function M.confirm(message)
    local input = vim.fn.input(message)
    return input == "" or input == "y" or input == "yes"
end

return M
