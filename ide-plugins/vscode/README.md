# Claude Code Statusline - VS Code Extension

Display Claude Code metrics directly in your VS Code status bar and sidebar.

## Features

- **Status Bar**: Real-time display of repository, costs, and MCP status
- **Activity Bar**: Dedicated sidebar with organized tree views
- **Detail Panel**: Full metrics view with responsive webview panel
- **Auto-refresh**: Configurable polling interval (1-60 seconds)
- **Theme Integration**: Respects VS Code color themes via CSS variables
- **Rich Tooltips**: Markdown-formatted hover information

## Screenshots

### Status Bar
```
✓ my-project | 💳 $0.42 | 🖥️ 3/5
```

### Activity Bar Views
- **Repository**: Name, branch, status, commits today, GitHub CI/PRs
- **Cost**: Session, daily, weekly, monthly breakdowns
- **MCP Servers**: Connection status and server list
- **System**: Theme, platform, modules loaded

## Requirements

- VS Code 1.85.0+
- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)
- JSON API enabled (default in v2.13.0+)

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
cd ide-plugins/vscode
npm install
npm run package
code --install-extension claude-code-statusline-0.1.0.vsix
```

### From Marketplace (Coming Soon)

```bash
code --install-extension rz1989s.claude-code-statusline
```

## Configuration

Access settings via `Preferences: Open Settings (UI)` and search for "Claude Statusline".

| Setting | Default | Description |
|---------|---------|-------------|
| `claudeStatusline.refreshInterval` | `5000` | Refresh interval in ms (1000-60000) |
| `claudeStatusline.statuslinePath` | `~/.claude/statusline/statusline.sh` | Path to script |
| `claudeStatusline.showStatusBar` | `true` | Show status bar item |
| `claudeStatusline.showCost` | `true` | Show session cost |
| `claudeStatusline.showMcp` | `true` | Show MCP server count |
| `claudeStatusline.showRepo` | `true` | Show repository info |
| `claudeStatusline.statusBarPosition` | `right` | Status bar position (left/right) |
| `claudeStatusline.statusBarPriority` | `100` | Priority (higher = more to the left) |

### Example settings.json

```json
{
  "claudeStatusline.refreshInterval": 3000,
  "claudeStatusline.showCost": true,
  "claudeStatusline.showMcp": true,
  "claudeStatusline.statusBarPosition": "right"
}
```

## Commands

Access via Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

| Command | Description |
|---------|-------------|
| `Claude Statusline: Show Details` | Open webview panel with all metrics |
| `Claude Statusline: Refresh` | Force refresh all data |
| `Claude Statusline: Toggle Status Bar` | Show/hide status bar item |

## Keybindings

Add to your `keybindings.json`:

```json
[
  {
    "key": "ctrl+shift+c",
    "command": "claude-statusline.show"
  },
  {
    "key": "ctrl+shift+r",
    "command": "claude-statusline.refresh"
  }
]
```

## Activity Bar

The extension adds a "Claude Code" view container to the Activity Bar with four tree views:

1. **Repository** - Git repository information
   - Name, branch, status
   - Commits today
   - GitHub CI status and open PRs (if enabled)

2. **Cost** - Usage costs breakdown
   - Session, daily, weekly, monthly

3. **MCP Servers** - Model Context Protocol status
   - Connection status
   - List of connected servers

4. **System** - Extension metadata
   - Theme, platform, modules loaded

## Troubleshooting

### Extension not loading

1. Verify statusline.sh exists:
   ```bash
   ls ~/.claude/statusline/statusline.sh
   ```

2. Check it's executable:
   ```bash
   chmod +x ~/.claude/statusline/statusline.sh
   ```

3. Test JSON output:
   ```bash
   ~/.claude/statusline/statusline.sh --json
   ```

### No data showing

1. Open Output panel (`View > Output`)
2. Select "Claude Statusline" from dropdown
3. Check for error messages
4. Run `Claude Statusline: Refresh` command

### Status bar not visible

1. Check `claudeStatusline.showStatusBar` is `true`
2. Try `Claude Statusline: Toggle Status Bar` command
3. Restart VS Code

### Activity bar views empty

1. Click the Claude Code icon in Activity Bar
2. If views show "No data", run `Claude Statusline: Refresh`
3. Check Output panel for errors

## API

The extension exposes these commands programmatically:

```typescript
// Show details panel
vscode.commands.executeCommand('claude-statusline.show');

// Force refresh
vscode.commands.executeCommand('claude-statusline.refresh');

// Toggle status bar
vscode.commands.executeCommand('claude-statusline.toggleStatusBar');
```

## Development

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch mode
npm run watch

# Lint
npm run lint

# Package VSIX
npm run package
```

### Project Structure

```
ide-plugins/vscode/
├── src/
│   └── extension.ts    # Main extension code
├── images/
│   └── icon.png        # Extension icon
├── package.json        # Extension manifest
├── tsconfig.json       # TypeScript config
└── README.md           # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with F5 in VS Code
5. Submit a pull request

## License

MIT
