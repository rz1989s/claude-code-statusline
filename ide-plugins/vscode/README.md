# Claude Code Statusline - VS Code Extension

Display Claude Code metrics directly in your VS Code status bar.

## Features

- **Status Bar**: Real-time display of repository, costs, and MCP status
- **Detail Panel**: Full metrics view with webview panel
- **Auto-refresh**: Configurable polling interval
- **Theme Integration**: Respects VS Code color themes

## Installation

### From Source (Development)

```bash
cd ide-plugins/vscode
npm install
npm run compile
```

Then press F5 in VS Code to launch Extension Development Host.

### From VSIX

```bash
npm run vscode:prepublish
npx vsce package
code --install-extension claude-code-statusline-0.1.0.vsix
```

## Requirements

- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)
- JSON API enabled (default in v2.13.0+)

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `claudeStatusline.refreshInterval` | `5000` | Refresh interval (ms) |
| `claudeStatusline.statuslinePath` | `~/.claude/statusline/statusline.sh` | Path to script |
| `claudeStatusline.showCost` | `true` | Show session cost |
| `claudeStatusline.showMcp` | `true` | Show MCP server count |

## Commands

- **Claude Statusline: Show Details** - Open detail panel
- **Claude Statusline: Refresh** - Force refresh

## Screenshots

Status bar:
```
✓ my-project | 💳 $0.42 | 🖥️ 3/5
```
