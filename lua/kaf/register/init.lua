local utils = require("kaf.utils")

local loaded = false
local M = {}

function M.setup()
    if loaded then
        return
    end

    local base = vim.fn.fnamemodify(utils.sourced_filepath(), ":h:h:h:h")
    local exe = base .. "/kaf/kaf"

    vim.fn["remote#host#Register"]("kaf", "x", function()
        return vim.fn.jobstart({ exe }, {
            rpc = true,
            detach = true,
            on_stderr = function(_, data, _)
                for _, line in ipairs(data) do
                    vim.print(line)
                end
            end,
        })
    end)

    vim.fn["remote#host#RegisterPlugin"]("kaf", "0", {
        {
            type = "function",
            name = "KafTopics",
            sync = true,
            opts = vim.empty_dict(),
        },
        {
            type = "function",
            name = "KafMessages",
            sync = true,
            opts = vim.empty_dict(),
        },
        {
            type = "function",
            name = "KafCreateTopic",
            sync = true,
            opts = vim.empty_dict(),
        },
        {
            type = "function",
            name = "KafDeleteTopic",
            sync = true,
            opts = vim.empty_dict(),
        },
        {
            type = "function",
            name = "KafProduce",
            sync = true,
            opts = vim.empty_dict(),
        },
        {
            type = "function",
            name = "KafJsonFormat",
            sync = true,
            opts = vim.empty_dict(),
        },
    })

    loaded = true
end

return M
