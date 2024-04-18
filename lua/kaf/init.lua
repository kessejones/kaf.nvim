require("kaf.message")
require("kaf.topic")

local M = {}

local Manager = require("kaf.manager")
local Data = require("kaf.data")
local config = require("kaf.config")
local logger = require("kaf.logger")

---@diagnostic disable-next-line: unused-local
local manager = nil

function M.setup(opts)
    opts = opts or {}

    local cache = Data.load_cache_file()
    ---@diagnostic disable-next-line: unused-local
    ---@diagnostic disable-next-line: undefined-field
    manager = Manager.new(cache.clients, cache.selected_client)

    vim.api.nvim_create_autocmd("User", {
        pattern = { "KafClientSelected", "KafTopicSelected", "KafClientRemoved" },
        callback = function()
            Data.save_cache_file(manager.selected_client, manager:all_clients())
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = { "KafFetchingMessages" },
        callback = function()
            require("kaf.integrations.fidget").progress("Kaf", "Fetching messages")
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = { "KafFetchedMessages" },
        callback = function()
            require("kaf.integrations.fidget").finish()
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = { "KafProducedMessage" },
        callback = function()
            require("kaf.integrations.fidget").notify("Produced Message")
        end,
    })

    vim.api.nvim_create_user_command("KafLogs", function()
        logger.show()
    end, {})
end

function M.manager()
    return manager
end

function M.produce(opts)
    opts = opts or {}

    config.setup(opts)

    local key = opts.key or nil
    if opts.ask_key then
        key = require("kaf.utils.ui").prompt("Key: ")
    end

    local value = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "")
    if opts.client == nil then
        ---@diagnostic disable-next-line: undefined-field,need-check-nil
        local client = manager:current_client()
        if not client then
            return
        end

        client:produce(key, value)
    end
end

return M
