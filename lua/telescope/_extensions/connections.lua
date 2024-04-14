local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("kaf.nvim requires nvim-telescope/telescope.nvim")
end

local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local connections = require("kaf.connections")

-- local ask_confirmation = function(question)
--     return vim.fn.input(question .. "[y/n]: ") == "y"
-- end

local function connections_finder()
    -- TODO: added brokers as preview to telescope
    local con_list = {}
    for _, connection in ipairs(connections.cache_connections()) do
        table.insert(con_list, connection.name)
    end

    return require("telescope.finders").new_table({
        results = con_list,
    })
end

local connection_actions = {
    select = function(bufnr)
        local connection = action_state.get_selected_entry()
        if not connection then
            return
        end

        local connection_name = connection[1]
        connections.select_connection(connection_name)
        actions.close(bufnr)
    end,
    create = function(bufnr)
        connections.create_connection()

        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(connections_finder(), { reset_prompt = true })
    end,
    delete = function(bufnr) end,
}

local M = {}

function M.picker_list_connections(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kaf Connections",
            finder = connections_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(connection_actions.select)

                map("i", "<c-n>", connection_actions.create)
                -- map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end

return M
