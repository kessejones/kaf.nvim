local manager = require("kaf.manager")
local config = require("kaf.config")
local notifier = require("kaf.notifier")
local ui = require("kaf.utils.ui")

local M = {}

---@param opts kaf.ProduceOpts
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

        if opts.value_from_buffer then
            if ui.confirm("Do you want to send this buffer to kafka " .. target .. "?[N]", "N") == false then
                return
            end
        else
            if ui.confirm("Do you want to produce a message on kafka " .. target .. "?[N]", "N") == false then
                return
            end
        end
    end

    local key = opts.key
    if opts.prompt_key then
        key = require("kaf.utils.ui").prompt("Key: ")
    end

    local value = opts.value or ""
    if opts.value_from_buffer then
        value = require("kaf.utils.buffer").get_buffer_content()
    end

    manager.produce_message(key, value)
end

return M
