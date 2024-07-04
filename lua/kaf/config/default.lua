local Job = require("kaf.utils.job")

local type_formatter = setmetatable({
    json = function(text)
        local output = Job.new("jq"):run_sync(text)
        if output.success == false then
            return { text }
        end
        return output.lines
    end,
}, {})

local type_detector = setmetatable({
    json = function(text)
        local pattern = "^%s*[%[%{].*[%]%}]%s*$"
        return string.match(text, pattern) ~= nil
    end,
}, {})

local M = {
    type_formatter = type_formatter,
    type_detector = type_detector,
    integrations = {
        fidget = true,
    },
    -- TODO: send this parameters to rpc process
    kafka = {
        max_messages_per_partition = 10,
    },
    confirm_on_produce_message = true,
}

return M
