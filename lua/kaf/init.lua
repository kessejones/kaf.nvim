local M = {}

local Manager = require("kaf.manager")
local Data = require("kaf.data")

---@diagnostic disable-next-line: unused-local
local manager = nil

function M.setup(opts)
    opts = opts or {}

    local cache = Data.load_cache_file()
    ---@diagnostic disable-next-line: unused-local
    ---@diagnostic disable-next-line: undefined-field
    manager = Manager.new(cache.clients, cache.selected_client)

    vim.api.nvim_create_autocmd("User", {
        pattern = { "KafClientSelected", "KafTopicSelected" },
        callback = function()
            Data.save_cache_file(manager.selected_client, manager:all_clients())
        end,
    })
end

function M.manager()
    return manager
end

return M
