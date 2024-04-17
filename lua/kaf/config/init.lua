local M = {}

-- TODO: added default config
local config = {
    default_formatter = "json",
    formatters = {
        json = function(text)
            local output = vim.fn.system(string.format([[echo '%s' | jq]], text))
            if vim.v.shell_error ~= 0 then
                return { text }
            end
            return vim.split(output, "\n")
        end,
    },
    integrations = {
        fidget = true,
    },
}

function M.setup(opts)
    opts = opts or {}
end

function M.config()
    return config
end

function M.run_default_formatter(text)
    local formatter = config.formatters[config.default_formatter]
    if not formatter then
        return { text }
    end
    return formatter(text)
end

return M
