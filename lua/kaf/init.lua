local EventType = require("kaf.types").EventType

local M = {}

local manager = require("kaf.manager")
local data = require("kaf.data")
local config = require("kaf.config")
local event = require("kaf.event")
local logger = require("kaf.logger")
local register = require("kaf.register")

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
        require("kaf.integrations.fidget").progress("Kaf", "Fetching messages")
    end)

    event.on(EventType.MessagesFetched, function()
        require("kaf.integrations.fidget").finish()
        require("kaf.integrations.fidget").notify("Messages Fetched")
    end)

    event.on(EventType.MessageProduced, function()
        require("kaf.integrations.fidget").notify("Message Produced")
    end)

    event.on(EventType.TopicsFetched, function(e)
        if e.forced then
            data.save_cache()
            require("kaf.integrations.fidget").notify("Topics Reloaded")
        end
    end)

    event.on(EventType.TopicCreated, function()
        require("kaf.integrations.fidget").notify("Topic Created")
    end)

    event.on(EventType.TopicDeleted, function()
        require("kaf.integrations.fidget").notify("Topic Deleted")
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

    local cache = data.load_cache_file()
    manager.setup(cache.clients, cache.selected_client)

    register_events()
    register_commands()
end

function M.produce(opts)
    opts = opts or {}

    local key = opts.key or nil
    if opts.ask_key then
        key = require("kaf.utils.ui").prompt("Key: ")
    end

    -- TODO: maybe we also can get value from a file picked by telescope

    local value = require("kaf.utils.buffer").get_buffer_content()
    manager.produce_message(key, value)
end

return M
