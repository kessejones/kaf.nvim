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

function M.progress(title, message, opts)
    opts = opts or {}

    if handle then
        handle:report({
            title = title,
            message = message,
            percentage = opts.percentage or 0,
        })
    else
        handle = fp.handle.create({
            title = title,
            message = message,
            percentage = 0,
        })
    end
end

function M.finish()
    if handle then
        handle:finish()
        handle = nil
    end
end

function M.notify(message)
    fidget.notify(message)
end

return M
