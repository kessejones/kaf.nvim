local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previwers = require("telescope.previewers")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local kaf = require("kaf")
local config = require("kaf.config")
local logger = require("kaf.logger")

local function messages_finder(opts)
    opts = opts or {}

    local manager = kaf.manager()
    local messages = manager:messages()
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 10 },
            { width = 5 },
            { width = 6 },
            { width = 10 },
            { width = 3 },
            { width = 5 },
            { width = 5 },
            { remaining = true },
        },
    })

    local nullable_field = function(value)
        value = vim.trim(value or "")
        if #value == 0 then
            return "NULL"
        end
        return value
    end

    local make_display = function(entry)
        local key = nullable_field(entry.key)
        local value = nullable_field(entry.value)

        return displayer({
            { "Partition", "TelescopeResultsField" },
            { entry.partition, "TelescopeResultsNumber" },
            { "Offset", "TelescopeResultsField" },
            { tostring(entry.offset), "TelescopeResultsNumber" },
            { "Key", "TelescopeResultsField" },
            { key, "TelescopeResultsIdentifier" },
            { "Value", "TelescopeResultsField" },
            { value, "TelescopeResultsIdentifier" },
        })
    end

    return require("telescope.finders").new_table({
        results = messages,
        entry_maker = function(entry)
            entry.ordinal = entry.value
            entry.display = make_display
            return make_entry.set_default_entry_mt(entry, opts)
        end,
    })
end

local message_actions = {
    select = vim.schedule_wrap(function(bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(bufnr)

        local buf = vim.api.nvim_create_buf(true, true)
        vim.cmd.buffer(buf)
        local format_result = config.apply_formatter(entry.value)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, format_result.text)
        vim.bo[buf].filetype = format_result.ft
        vim.bo[buf].modifiable = false
    end),
    refresh = function(bufnr)
        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(messages_finder(), { reset_prompt = true })
    end,
}

return function(opts)
    opts = opts or {}

    -- TODO: check if we have a topic selected
    local client = kaf.manager():current_client()
    if not client then
        error("client is not selected")
        return
    end
    local topic_name = client.selected_topic

    opts.results_title = string.format("Messages topic: %s ", topic_name)

    require("telescope.pickers")
        .new(opts, {
            finder = messages_finder(),
            prompt_title = "Find messages",
            previewer = previwers.new_buffer_previewer({
                title = "Message Data",
                define_preview = vim.schedule_wrap(function(self, entry)
                    local result_format = config.apply_formatter(entry.value)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, result_format.text)
                    vim.bo[self.state.bufnr].filetype = result_format.ft
                end),
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(message_actions.select)

                map("i", "<c-r>", message_actions.refresh)
                return true
            end,
        })
        :find()
end
