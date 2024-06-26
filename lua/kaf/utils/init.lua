local M = {}

function M.sourced_filepath()
    return debug.getinfo(2, "S").source:sub(2)
end

return M
