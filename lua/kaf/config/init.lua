local default = require("kaf.config.default")

local M = {}

local config = {}

function M.setup(opts)
    opts = opts or {}

    config = vim.tbl_extend("force", opts, default)
end

function M.data()
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
