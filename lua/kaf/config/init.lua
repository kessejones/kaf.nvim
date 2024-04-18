local M = {}

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

local config = {
    type_formatter = type_formatter,
    type_detector = type_detector,
    integrations = {
        fidget = true,
    },
}

---TODO: Implement merge options with default config
function M.setup(opts)
    opts = opts or {}
end

function M.config()
    return config
end

--Return the first type that matches the text or `text` as fallback
---@param text string
---@return string
function M.detect_type(text)
    for type, detector in pairs(config.type_detector) do
        if detector(text) then
            return type
        end
    end
    return "text"
end

--Type formatter for the given type
---@param type string
function M.formatter(type)
    return config.type_formatter[type]
end

--Apply the formatter for the given text
function M.apply_formatter(text)
    local type = M.detect_type(text)
    local formatter = M.formatter(type)
    if not formatter then
        return { ft = type, text = { text } }
    end
    return { ft = type, text = formatter(text) }
end

return M
