local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local ui = require("kaf.utils.ui")
local previwers = require("telescope.previewers")

local kaf = require("kaf")

local function prompt_new_client()
    local name = vim.fn.input("Client name: ")
    if #name == 0 then
        return nil
    end
    local brokers = vim.split(vim.fn.input("Brokers list (separete by comma): "), ",")
    if #brokers == 0 then
        return nil
    end

    return {
        name = name,
        brokers = brokers,
    }
end

local function clients_finder()
    local manager = kaf.manager()
    local clients = manager:all_clients()
    return require("telescope.finders").new_table({
        results = clients,
        entry_maker = function(entry)
            return {
                value = entry,
                display = entry.name,
                ordinal = entry.name,
            }
        end,
    })
end

local client_actions = {
    select = function(bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then
            return
        end
        local client_name = entry.value.name
        local manager = require("kaf").manager()
        manager:set_client(client_name)
        actions.close(bufnr)
    end,
    create = function(bufnr)
        local new_client = prompt_new_client()
        if new_client == nil then
            error("Invalid client name or brokers")
            return
        end

        kaf.manager():create_client(new_client.name, new_client.brokers)

        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(clients_finder(), { reset_prompt = true })
    end,
    delete = function(bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then
            return
        end
        local client_name = entry[1]

        if not ui.confirm("Are you sure you want to delete " .. client_name .. "? [Y] ") then
            return
        end

        kaf.manager():remove_client(client_name)
        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(clients_finder(), { reset_prompt = true })
    end,
}

return function(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Clients",
            finder = clients_finder(),
            previewer = previwers.new_buffer_previewer({
                title = "Client Data",
                define_preview = function(self, entry)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.brokers)
                end,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(client_actions.select)

                map("i", "<c-n>", client_actions.create)
                map("i", "<c-x>", client_actions.delete)
                return true
            end,
        })
        :find()
end
