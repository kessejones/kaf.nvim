local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local kaf = require("kaf")

local function topics_finder()
    local manager = kaf.manager()
    local client = manager:current_client()

    local topics = {}
    if client ~= nil then
        topics = client:topics()
    end

    return require("telescope.finders").new_table({
        results = topics,
    })
end

local topic_actions = {
    select = function(bufnr)
        local topic = action_state.get_selected_entry()
        if not topic then
            return
        end
        local topic_name = topic[1]
        local manager = kaf.manager()
        local client = manager:current_client()
        client:select_topic(topic_name)
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
