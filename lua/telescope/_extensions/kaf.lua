local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("kaf.nvim requires nvim-telescope/telescope.nvim")
end
local conf = require("telescope.config").values
local themes = require("telescope.themes")
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local ask_confirmation = function(question)
    return vim.fn.input(question .. "[y/n]: ") == "y"
end

local function topics_finder()
    local topics = require("kaf.wrapper").list_topics()
    return require("telescope.finders").new_table({
        results = topics,
    })
end

local function clusters_finder()
    local clusters = require("kaf.wrapper").list_clusters()
    return require("telescope.finders").new_table({
        results = clusters,
    })
end

local topic_actions = {
    select = function()
        local topic = action_state.get_selected_entry()
        if not topic then
            return
        end
        local topic_name = topic[1]

        -- TODO: check if there is a better way to do this
        vim.g.kaf_default_topic_name = topic_name

        vim.print("topic " .. topic_name .. " selected")
    end,
    create = function(bufnr)
        local input_value = vim.fn.input("Create topic: ")
        if input_value == "" then
            return
        end

        require("kaf.wrapper").create_topic(input_value)

        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(topics_finder(), { reset_prompt = true })
    end,
    delete = function(bufnr)
        local topic = action_state.get_selected_entry()
        if not topic then
            return
        end
        local topic_name = topic[1]
        if not ask_confirmation("Delete topic " .. topic_name .. "?") then
            return
        end

        require("kaf.wrapper").delete_topic(topic_name)
        local current_picker = action_state.get_current_picker(bufnr)
        current_picker:refresh(topics_finder(), { reset_prompt = true })
    end,
}

local cluster_actions = {
    select = function(bufnr)
        local cluster = action_state.get_selected_entry()
        if not cluster then
            return
        end
        local cluster_name = cluster[1]
        require("kaf.wrapper").select_cluster(cluster_name)
        actions.close(bufnr)
    end,
    create = function(bufnr) end,
    delete = function(bufnr) end,
}

local function picker_list_topics(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Topics",
            finder = topics_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(topic_actions.select)

                map("i", "<c-n>", topic_actions.create)
                map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end

local function picker_list_clusters(opts)
    opts = opts or {}

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "Kafka Clusters",
            finder = clusters_finder(),
            previewer = nil,
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(_, map)
                action_set.select:replace(cluster_actions.select)

                -- map("i", "<c-n>", topic_actions.create)
                -- map("i", "<c-x>", topic_actions.delete)
                return true
            end,
        })
        :find()
end

return telescope.register_extension({
    exports = {
        list_topics = picker_list_topics,
        list_clusters = picker_list_clusters,
    },
})
