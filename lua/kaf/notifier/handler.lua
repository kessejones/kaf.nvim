local M = {}

function M.notify(message, level)
    vim.notify(message, level)
end

function M.progress(opts)
    opts = opts or {}

    vim.notify(opts.message)
end

function M.cancel() end
function M.finish() end

--
return M
