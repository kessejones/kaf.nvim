return {
    clients = vim.schedule_wrap(require("kaf.integrations.telescope.clients")),
    topics = vim.schedule_wrap(require("kaf.integrations.telescope.topics")),
    messages = vim.schedule_wrap(require("kaf.integrations.telescope.messages")),
}
