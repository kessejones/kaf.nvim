local Job = require("kaf.utils.job")

local M = {}

-- TODO: validate inputs to actions
-- TODO: check errors from all actions

function M.list_topics()
    local job = Job.new({ "kaf", "topics", "--no-headers" })

    local output = job:run_sync()

    local topics = {}
    for _, topic in ipairs(output) do
        local topic_name = topic:match("^%a+")
        table.insert(topics, topic_name)
    end

    return topics
end

function M.create_topic(topic_name)
    if topic_name == nil or topic_name == "" then
        error("topic_name must be a string")
    end

    local job = Job.new({ "kaf", "topic", "create", topic_name })
    job:run_sync()
end

function M.delete_topic(topic_name)
    if topic_name == nil or topic_name == "" then
        error("topic_name must be a string")
    end

    local job = Job.new({ "kaf", "topic", "delete", topic_name })
    job:run_sync()
end

function M.list_clusters()
    local job = Job.new({ "kaf", "config", "get-clusters", "--no-headers" })
    return job:run_sync()
end

function M.select_cluster(cluster_name)
    local job = Job.new({ "kaf", "config", "use-cluster", cluster_name })
    return job:run_sync()
end

return M
