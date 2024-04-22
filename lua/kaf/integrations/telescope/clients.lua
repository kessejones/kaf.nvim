local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local ui = require("kaf.utils.ui")
local previwers = require("telescope.previewers")

local notify = require("kaf.notify")
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

local function prompt_edit_client(name, brokers)
    local brokers_str = table.concat(brokers, ", ")
    local new_brokers =
        vim.split(vim.fn.input("Brokers list for client " .. name .. " (separete by comma): ", brokers_str), ",")
    if #brokers == 0 then
        return nil
    end

    if table.concat(brokers) == table.concat(new_brokers) then
        return nil
    end

    return {
        brokers = new_brokers,
    }
end

local function clients_finder()
    local manager = kaf.manager()
    local clients = vim.deepcopy(manager:all_clients())

    return require("telescope.finders").new_table({
        results = clients,
        entry_maker = function(entry)
            return {
                value = { name = entry.name, brokers = entry.brokers },
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
        local manager = kaf.manager()
        manager:set_client(entry.value.name)
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
    edit = function(bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then
            return
        end
        local client = kaf.manager():get_client(entry.value.name)
        local new_data = prompt_edit_client(client.name, client.brokers)
        if new_data == nil then
            notify.notify("Client edition canceled")
            return
        end

        client:set_brokers(new_data.brokers)
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
                title = "Client Config",
                define_preview = function(self, entry)
                    local brokers = vim.tbl_map(function(broker)
                        return "  - " .. broker
                    end, entry.value.brokers)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.tbl_flatten({ "Brokers:", brokers }))
                    vim.bo[self.state.bufnr].filetype = "yaml"
                end,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(client_actions.select)

                map("i", "<c-n>", client_actions.create)
                map("i", "<c-x>", client_actions.delete)
                map("i", "<c-e>", client_actions.edit)
                return true
            end,
        })
        :find()
end
