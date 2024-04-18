local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local kaf = require("kaf")

local function topics_finder(opts)
    local manager = kaf.manager()
    local client = manager:current_client()

    local topics = {}
    if client ~= nil then
        topics = vim.deepcopy(client:topics(true))
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 20 },
            { width = 10 },
            { width = 10 },
        },
    })

    local make_display = function(entry)
        return displayer({
            { entry.name, "TelescopeResultsIdentifier" },
            { "Partitions", "TelescopeResultsField" },
            { tostring(entry.partitions), "TelescopeResultsNumber" },
        })
    end

    return require("telescope.finders").new_table({
        results = topics,
        entry_maker = function(entry)
            entry.value = entry.name
            entry.ordinal = entry.name
            entry.display = make_display
            return make_entry.set_default_entry_mt(entry, opts)
        end,
    })
end

local topic_actions = {
    select = function(bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then
            return
        end
        local manager = kaf.manager()
        local client = manager:current_client()
        client:select_topic(entry.value)
        actions.close(bufnr)
    end,
    create = function(bufnr) end,
    delete = function(bufnr) end,
}

return function(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Topics",
            finder = topics_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(topic_actions.select)

                -- map("i", "<c-n>", topic_actions.create)
                -- map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end
