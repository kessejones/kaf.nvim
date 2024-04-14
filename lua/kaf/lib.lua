local libkaf = require("libkaf")
local connections = require("kaf.connections")

local M = {}

function M.get_topics(opts)
    opts = opts or {}

    local connection = connections.selected_connection()
    if connection ~= nil then
        opts.brokers = connection.brokers
    end

    return libkaf.get_topics(opts)
end

return M
