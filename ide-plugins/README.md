# IDE Plugins for Claude Code Statusline

Native IDE integrations that consume the `--json` API from `statusline.sh`.

## Available Plugins

| Plugin | Status | Platform |
|--------|--------|----------|
| [VS Code](./vscode/) | Development | VS Code, Cursor |
| [Neovim](./neovim/) | Development | Neovim 0.8+ |
| [Emacs](./emacs/) | Development | Emacs 27+ |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     statusline.sh --json                     │
│                              │                               │
│                              ▼                               │
│                    ┌─────────────────┐                       │
│                    │  JSON API Output │                      │
│                    └────────┬────────┘                       │
│                              │                               │
│         ┌────────────────────┼────────────────────┐          │
│         ▼                    ▼                    ▼          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   VS Code    │    │    Neovim    │    │    Emacs     │   │
│  │  Extension   │    │    Plugin    │    │   Package    │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## JSON API Schema

See [shared/schema.json](./shared/schema.json) for the complete TypeScript-compatible schema.

Example output:
```json
{
  "version": "2.13.0",
  "timestamp": 1735530000,
  "repository": {
    "name": "my-project",
    "branch": "main",
    "status": "clean",
    "commits_today": 5
  },
  "cost": {
    "session": 0.42,
    "daily": 2.15,
    "weekly": 12.50,
    "monthly": 45.00
  },
  "mcp": {
    "connected": 3,
    "total": 5,
    "servers": ["filesystem", "github", "memory"]
  }
}
```

## Contributing

1. Each plugin follows its ecosystem's conventions
2. All plugins consume the same JSON API
3. Test with: `~/.claude/statusline/statusline.sh --json | jq`

## Development

```bash
# Test JSON API
./statusline.sh --json

# VS Code
cd ide-plugins/vscode && npm install && npm run compile

# Neovim (add to config)
# use { 'rz1989s/claude-code-statusline', rtp = 'ide-plugins/neovim' }

# Emacs (add to load-path)
# (add-to-list 'load-path "~/.claude/statusline/ide-plugins/emacs")
```
