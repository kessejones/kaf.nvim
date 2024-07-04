local M = {}

local fidget = require("fidget")
local fp = require("fidget.progress")

local handle = nil

function M.cancel()
    if handle then
        handle:finish()
        handle = nil
    end
end

---@param opts Notification
function M.progress(opts)
    opts.percentage = opts.percentage or 0

    if handle then
        handle:report(opts)
    else
        handle = fp.handle.create(opts)
    end
end

function M.finish()
    if handle then
        handle:finish()
        handle = nil
    end
end

---@param message string
function M.notify(message, level)
    fidget.notify(message, level)
end

return M
