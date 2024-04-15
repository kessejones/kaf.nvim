local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previwers = require("telescope.previewers")

local kaf = require("kaf")

local function format_json(text)
    return vim.fn.system(string.format([[echo '%s' | jq]], text))
end

local function messages_finder()
    local manager = kaf.manager()
    local client = manager:current_client()
    local messages = client:messages()

    return require("telescope.finders").new_table({
        results = messages,
        entry_maker = function(entry)
            local key = entry.key
            if not key or #key == 0 then
                key = "NULL"
            end

            return {
                value = entry.value,
                display = string.format(
                    "partition:%d - offset:%d - key:%s - value: %s",
                    entry.partition,
                    entry.offset,
                    key,
                    entry.value
                ),
                ordinal = tostring(entry.offset),
            }
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
