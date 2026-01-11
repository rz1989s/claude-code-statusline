# Claude Code Statusline - Neovim Plugin

Display Claude Code metrics in Neovim statusline and floating windows.

## Features

- **Lualine Integration**: Drop-in component for lualine.nvim
- **Floating Window**: Detailed metrics popup with syntax highlighting
- **Telescope Picker**: Browse metrics with fuzzy search
- **Async Refresh**: Non-blocking background updates via vim.loop
- **Caching**: Efficient data fetching with configurable TTL
- **Commands**: `:ClaudeStatusline`, `:ClaudeStatuslineRefresh`, `:ClaudeStatuslineTelescope`

## Requirements

- Neovim 0.8+
- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)
- Optional: [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) for statusline integration
- Optional: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for picker

## Installation

### lazy.nvim (Recommended)

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

### Manual Installation

```bash
# Clone or symlink to your Neovim runtime
mkdir -p ~/.local/share/nvim/site/pack/claude/start/
ln -s ~/.claude/statusline/ide-plugins/neovim ~/.local/share/nvim/site/pack/claude/start/claude-statusline
```

Then in your `init.lua`:

```lua
require('claude-statusline').setup()
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
| `:ClaudeStatuslineTelescope` | Open Telescope picker |

## Keymaps

```lua
-- Suggested keymaps
vim.keymap.set('n', '<leader>cs', ':ClaudeStatusline<CR>', { desc = 'Claude Statusline' })
vim.keymap.set('n', '<leader>cS', ':ClaudeStatuslineTelescope<CR>', { desc = 'Claude Telescope' })
```

## Configuration

```lua
require('claude-statusline').setup({
  -- Path to statusline.sh
  statusline_path = '~/.claude/statusline/statusline.sh',

  -- Refresh interval in milliseconds (0 to disable auto-refresh)
  refresh_interval = 5000,

  -- Components to show in statusline
  show_cost = true,
  show_mcp = true,
  show_repo = true,
  show_icon = true,

  -- Custom icons (requires Nerd Font)
  icons = {
    claude = '',
    clean = '',
    dirty = '',
    mcp = '',
    cost = '',
  },
})
```

## API

```lua
local claude = require('claude-statusline')

-- Get formatted status string
local status = claude.status()

-- Get raw data table
local data = claude.get_data()

-- Show details floating window
claude.show_details()

-- Open Telescope picker
claude.telescope_picker()

-- Manual refresh
claude.refresh()

-- Get lualine component config
local component = claude.lualine_component()
```

## Highlight Groups

The plugin defines these highlight groups for customization:

| Group | Default | Description |
|-------|---------|-------------|
| `ClaudeTitle` | Blue, bold | Section titles |
| `ClaudeBorder` | Gray | Separator lines |
| `ClaudeLabel` | Light gray | Field labels |
| `ClaudeValue` | White | Field values |
| `ClaudeCost` | Green | Cost values |
| `ClaudeMcp` | Yellow | MCP server info |
| `ClaudeClean` | Green | Clean git status |
| `ClaudeDirty` | Red | Dirty git status |

Override in your config:

```lua
vim.api.nvim_set_hl(0, 'ClaudeTitle', { fg = '#ff79c6', bold = true })
```

## Troubleshooting

### Plugin not loading

1. Verify statusline.sh exists: `ls ~/.claude/statusline/statusline.sh`
2. Check it's executable: `chmod +x ~/.claude/statusline/statusline.sh`
3. Test JSON output: `~/.claude/statusline/statusline.sh --json`

### No data showing

1. Run `:ClaudeStatuslineRefresh` to force refresh
2. Check `:messages` for errors
3. Verify path in config matches your installation

### Statusline not updating

The plugin caches data based on `refresh_interval`. Either:
- Wait for the next refresh cycle
- Run `:ClaudeStatuslineRefresh` to force update
- Reduce `refresh_interval` in config

## License

MIT
