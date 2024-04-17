local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previwers = require("telescope.previewers")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local kaf = require("kaf")

local function format_json(text)
    return vim.fn.system(string.format([[echo '%s' | jq]], text))
end

local function messages_finder(opts)
    opts = opts or {}

    local manager = kaf.manager()
    local client = manager:current_client()
    local messages = client:messages()

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 10 },
            { width = 5 },
            { width = 10 },
            { width = 5 },
            { width = 5 },
            { width = 5 },
            { width = 5 },
            { remaining = true },
        },
    })

    local make_display = function(entry)
        local key = vim.trim(entry.key or "")
        if #key == 0 then
            key = "NULL"
        end

        return displayer({
            { "Partition", "TelescopeResultsField" },
            { entry.partition, "TelescopeResultsNumber" },
            { "Offset", "TelescopeResultsField" },
            { tostring(entry.offset), "TelescopeResultsNumber" },
            { "Key", "TelescopeResultsField" },
            { key, "TelescopeResultsIdentifier" },
            { "Value", "TelescopeResultsField" },
            { entry.value, "TelescopeResultsIdentifier" },
        })
    end

    return require("telescope.finders").new_table({
        results = messages,
        entry_maker = function(entry)
            entry.value = entry.value
            entry.ordinal = tostring(entry.partition)
            entry.display = make_display
            return make_entry.set_default_entry_mt(entry, opts)
        end,
    })
end

local message_actions = {
    select = function(bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(bufnr)

        local buf = vim.api.nvim_create_buf(true, true)
        vim.cmd.buffer(buf)
        -- TODO: detect if jq is installed and if content type is json
        local output = format_json(entry.value)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))
        vim.bo[buf].filetype = "json"
        vim.bo[buf].modifiable = false
    end,
    create = function(bufnr) end,
    delete = function(bufnr) end,
}

return function(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Messages",
            finder = messages_finder(),
            previewer = previwers.new_buffer_previewer({
                title = "Message Data",
                define_preview = function(self, entry)
                    -- TODO: detect if jq is installed and if content type is json
                    local output = format_json(entry.value)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output, "\n"))
                    vim.bo[self.state.bufnr].filetype = "json"
                end,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(message_actions.select)

                -- map("i", "<c-n>", topic_actions.create)
                -- map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end
