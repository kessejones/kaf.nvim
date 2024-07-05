local EventType = require("kaf.types").EventType

local M = {}

local manager = require("kaf.manager")
local data = require("kaf.data")
local config = require("kaf.config")
local event = require("kaf.event")
local logger = require("kaf.logger")
local register = require("kaf.register")
local notifier = require("kaf.notifier")
local integrations = require("kaf.integrations")

local function register_events()
    event.on({
        EventType.ClientSelected,
        EventType.TopicSelected,
        EventType.ClientRemoved,
        EventType.ClientCreated,
        EventType.TopicSelected,
    }, function()
        data.save_cache()
    end)

    event.on(EventType.MessagesFetching, function()
        notifier.progress({ title = "Kaf", message = "Fetching Messages" })
    end)

    event.on(EventType.MessagesFetched, function()
        notifier.finish()
        notifier.notify("Messages Fetched")
    end)

    event.on(EventType.MessageProduced, function()
        notifier.notify("Message Produced")
    end)

    event.on(EventType.TopicsFetched, function(e)
        if e.forced then
            data.save_cache()
            notifier.notify("Topics Reloaded")
        end
    end)

    event.on(EventType.TopicCreated, function()
        notifier.notify("Topic Created")
    end)

    event.on(EventType.TopicDeleted, function()
        notifier.notify("Topic Deleted")
    end)
end

local function register_commands()
    vim.api.nvim_create_user_command("KafLogs", function()
        logger.show()
    end, {})

    vim.api.nvim_create_user_command("KafReloadCache", function()
        local cache = data.load_cache_file()
        manager.setup(cache.clients, cache.selected_client)
    end, {})

    vim.api.nvim_create_user_command("KafSaveCache", function()
        data.save_file()
    end, {})

    vim.api.nvim_create_user_command("KafDeleteCache", function()
        data.delete_cache()
        manager.setup({}, nil)
    end, {})
end

function M.setup(opts)
    opts = opts or {}

    register.setup()
    config.setup(opts)
    notifier.setup()
    integrations.setup()

    local cache = data.load_cache_file()
    manager.setup(cache.clients, cache.selected_client)

    register_events()
    register_commands()
end

return M
