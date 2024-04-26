local type_formatter = setmetatable({
    json = function(text)
        local output = vim.fn.system(string.format([[echo '%s' | jq]], text))
        if vim.v.shell_error ~= 0 then
            return { text }
        end
        return vim.split(output, "\n")
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
}

return M
