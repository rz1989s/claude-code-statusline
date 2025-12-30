# Claude Code Statusline - Neovim Plugin

Display Claude Code metrics in Neovim status line and floating windows.

## Features

- **Lualine Integration**: Drop-in component for lualine.nvim
- **Floating Window**: Detailed metrics popup
- **Caching**: Efficient data fetching with configurable TTL
- **Commands**: `:ClaudeStatusline` and `:ClaudeStatuslineRefresh`

## Installation

### lazy.nvim

```lua
{
  'rz1989s/claude-code-statusline',
  config = function()
    require('claude-statusline').setup({
      statusline_path = '~/.claude/statusline/statusline.sh',
      refresh_interval = 5000,
      show_cost = true,
      show_mcp = true,
    })
  end,
  -- Load from subdirectory
  dir = vim.fn.expand('~/.claude/statusline/ide-plugins/neovim'),
}
```

### packer.nvim

```lua
use {
  'rz1989s/claude-code-statusline',
  rtp = 'ide-plugins/neovim',
  config = function()
    require('claude-statusline').setup()
  end,
}
```

## Lualine Integration

```lua
require('lualine').setup {
  sections = {
    lualine_x = {
      require('claude-statusline').lualine_component(),
    }
  }
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:ClaudeStatusline` | Show floating window with details |
| `:ClaudeStatuslineRefresh` | Clear cache and refresh data |

## Keymaps

```lua
-- Suggested keymap
vim.keymap.set('n', '<leader>cs', ':ClaudeStatusline<CR>', { desc = 'Claude Statusline' })
```

## Configuration

```lua
require('claude-statusline').setup({
  -- Path to statusline.sh
  statusline_path = '~/.claude/statusline/statusline.sh',

  -- Refresh interval in milliseconds
  refresh_interval = 5000,

  -- Components to show
  show_cost = true,
  show_mcp = true,
  show_repo = true,
})
```

## API

```lua
local claude = require('claude-statusline')

-- Get status string
local status = claude.status()

-- Get raw data table
local data = claude.get_data()

-- Show details popup
claude.show_details()
```

## Requirements

- Neovim 0.8+
- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)
