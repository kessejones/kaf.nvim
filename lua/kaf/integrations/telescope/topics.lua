local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local logger = require("kaf.logger")
local kaf = require("kaf")
local ui = require("kaf.utils.ui")
local notify = require("kaf.notify")

local function prompt_new_topic()
    local name = vim.fn.input("Topic name: ")
    if #name == 0 then
        return nil
    end

    local num_partitions = vim.fn.input("Number of partitions [1]: ")
    if #num_partitions == 0 then
        num_partitions = 1
    else
        num_partitions = tonumber(num_partitions)
    end

    return {
        name = name,
        num_partitions = num_partitions,
    }
end

local function topics_finder(opts)
    opts = opts or {}

    local manager = kaf.manager()
    local result_topics = manager:topics(opts.force_refresh)

    if result_topics.has_error then
        vim.notify("Kaf Error:" .. result_topics.error)
        logger.error(result_topics.error)

        return
    end

    local topics = vim.deepcopy(result_topics.data)

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 80 },
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
        kaf.manager():select_topic(entry.value)

        notify.notify("Topic '" .. entry.value .. "' selected as default")

        actions.close(bufnr)
    end,
    create = function(bufnr)
        local new_topic = prompt_new_topic()
        if new_topic == nil then
            vim.notify("Topic creation cancelled")
            return
        end
        kaf.manager():create_topic(new_topic.name, new_topic.num_partitions)

        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(topics_finder({ force_refresh = true }), { reset_prompt = true })
    end,
    delete = function(bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then
            return
        end

        if not ui.confirm("Do you want to delete topic " .. entry.value .. "?[N]", "N") then
            notify.notify("Topic deletion cancelled")
            return
        end

        if kaf.manager():delete_topic(entry.value) then
            local current_picker = action_state.get_current_picker(bufnr)
            current_picker:refresh(topics_finder({ force_refresh = false }), { reset_prompt = true })
        end
    end,
    refresh = function(bufnr)
        notify.notify("Refreshing topics list")

        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(topics_finder({ force_refresh = true }), { reset_prompt = true })
    end,
}

return function(opts)
    opts = opts or {}

    opts.results_title = "Topics"

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Find Topics",
            finder = topics_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(topic_actions.select)

                map("i", "<C-r>", topic_actions.refresh)
                map("i", "<C-n>", topic_actions.create)
                map("i", "<C-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end
