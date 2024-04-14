local M = {}

_G.kaf_cache = {
    topics = {},
    selected_topic = nil,
}

function M.setup(opts)
    opts = opts or {}

    vim.opt.rtp:prepend(require("kaf.utils.lib").find_lib_path())

    require("kaf.connections").cache_connections()
end

return M
