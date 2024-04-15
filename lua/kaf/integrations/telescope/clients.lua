local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function clients_finder()
    local manager = require("kaf").manager()

    local clients = {}
    for _, client in ipairs(manager:all_clients()) do
        table.insert(clients, client.name)
    end

    return require("telescope.finders").new_table({
        results = clients,
    })
end

local client_actions = {
    select = function(bufnr)
        local cluster = action_state.get_selected_entry()
        if not cluster then
            return
        end
        local client_name = cluster[1]
        local manager = require("kaf").manager()
        manager:set_client(client_name)
        actions.close(bufnr)
    end,
    create = function(bufnr) end,
    delete = function(bufnr) end,
}

return function(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Clients",
            finder = clients_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(client_actions.select)

                -- map("i", "<c-n>", topic_actions.create)
                -- map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end
