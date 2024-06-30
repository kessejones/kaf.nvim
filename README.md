## Kaf.nvim

A plugin for manager kafka topics and messages

## Getting Started

[Neovim 0.9](https://github.com/neovim/neovim/releases/tag/v0.9.5) or higher is required for `kaf.nvim` to work.

### Dependencies

- [telescope](https://github.com/nvim-telescope/telescope.nvim)

### Installation

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    'kessejones/kaf.nvim',
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
}

```

#### Usage

You can configure your key mappings like this example.

```lua
local telescope = require('telescope')

vim.keymap.set('n', telescope.extensions.kaf.clients, { desc = "List clients entries" })
vim.keymap.set('n', telescope.extensions.kaf.topics, { desc = "List topics from selected client" })
vim.keymap.set('n', telescope.extensions.kaf.messages, { desc = "List messages from seleted topic and client" })

vim.keymap.set('n', require('kaf').produce, { desc = "Produce a message into selected topic and client" })
```

#### Mappings

| Mappings | Prompt   | Action                                            |
| -------- | -------- | ------------------------------------------------- |
| `<CR>`   | Clients  | Set selected client as default                    |
| `<C-n>`  | Clients  | Create a new client                               |
| `<C-x>`  | Clients  | Remove selected client                            |
| `<CR>`   | Topics   | Set selected topic as default                     |
| `<C-n>`  | Topics   | Create a new topic in this client                 |
| `<C-x>`  | Topics   | Delete selected topic                             |
| `<CR>`   | Messages | Open the selected message value into a new buffer |

## Contributing

All contributions are welcome! Just open a pull request.

Please look at the Issues page to see the current backlog, suggestions, and bugs to work.
