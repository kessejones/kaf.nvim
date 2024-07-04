local config = require("kaf.config")

local M = {}

local handler = nil

function M.setup()
    if config.data().integrations.fidget then
        handler = require("kaf.integrations.fidget")
    else
        handler = require("kaf.notifier.handler")
    end
end

return setmetatable(M, {
    __index = function(_tbl, key)
        if handler == nil then
            vim.notify("Notifier is not initialized", vim.log.levels.WARN)
            return
        end
        return handler[key]
    end,
})
