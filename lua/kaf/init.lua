local themes = require("telescope.themes")

local M = {}

function M.setup(opts)
    opts = opts or {}

    vim.keymap.set("n", "<leader>ee", function()
        local opts = themes.get_dropdown({
            layout_config = {
                height = 25,
                width = 60,
            },
        })
        require("telescope").extensions.kaf.list_topics(opts)
    end)

    vim.keymap.set("n", "<leader>ef", function()
        local opts = themes.get_dropdown({
            layout_config = {
                height = 25,
                width = 60,
            },
        })
        require("telescope").extensions.kaf.list_clusters(opts)
    end)
end

return M
