local EventType = require("kaf.types").EventType

local M = {}

local manager = require("kaf.manager")
local data = require("kaf.data")
local config = require("kaf.config")
local event = require("kaf.event")
local logger = require("kaf.logger")
local register = require("kaf.register")
local notifier = require("kaf.notifier")

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

    local cache = data.load_cache_file()
    manager.setup(cache.clients, cache.selected_client)

    register_events()
    register_commands()
end

function M.produce(opts)
    opts = opts or {}

    if config.data().confirm_on_produce_message then
        local client = manager.current_client()
        if not client then
            notifier.notify("You need to select a client first", vim.log.levels.WARN)
            return
        end

        if not client.selected_topic then
            notifier.notify("You need to select a topic in the client " .. client.name .. " first", vim.log.levels.WARN)
            return
        end

        local target = string.format("(%s/%s)", client.name, client.selected_topic)
        if
            require("kaf.utils.ui").confirm("Do you want to send this buffer to kafka " .. target .. "?[N]", "N")
            == false
        then
            return
        end
    end

    local key = opts.key or nil
    if opts.ask_key then
        key = require("kaf.utils.ui").prompt("Key: ")
    end

    local value = require("kaf.utils.buffer").get_buffer_content()
    manager.produce_message(key, value)
end

return M
