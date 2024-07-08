---@type kaf.TypeFormatter
local type_formatter = setmetatable({
    json = function(text)
        local ok, json_lines = pcall(vim.fn.KafJsonFormat, { value = text, indent = 4 })
        if ok then
            return json_lines
        end
        return { text }
    end,
}, {})

---@type kaf.TypeDetector
local type_detector = setmetatable({
    json = function(text)
        local pattern = "^%s*[%[%{].*[%]%}]%s*$"
        return string.match(text, pattern) ~= nil
    end,
}, {})

---@type kaf.KafOpts
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
