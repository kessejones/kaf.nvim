local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("kaf.nvim requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
    exports = {
        topics = require("kaf.integrations.telescope.topics"),
        clients = require("kaf.integrations.telescope.clients"),
        messages = require("kaf.integrations.telescope.messages"),
    },
})
