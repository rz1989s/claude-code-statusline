# Claude Code Statusline - Emacs Package

Display Claude Code metrics in Emacs mode-line and popup buffers.

## Features

- **Mode-line Integration**: Real-time metrics with syntax highlighting
- **Doom Modeline**: Native segment support
- **Popup Buffer**: Detailed view with `M-x claude-statusline-show`
- **Auto-refresh**: Timer-based updates with configurable interval
- **Async Fetching**: Optional non-blocking data updates
- **8 Custom Faces**: Catppuccin-inspired color scheme

## Requirements

- Emacs 27.1+
- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)

## Installation

### Manual

```elisp
(add-to-list 'load-path "~/.claude/statusline/ide-plugins/emacs")
(require 'claude-statusline)
(claude-statusline-mode 1)
```

### use-package

```elisp
(use-package claude-statusline
  :load-path "~/.claude/statusline/ide-plugins/emacs"
  :config
  (claude-statusline-mode 1))
```

### straight.el

```elisp
(straight-use-package
 '(claude-statusline :type git
                     :host github
                     :repo "rz1989s/claude-code-statusline"
                     :files ("ide-plugins/emacs/*.el")))
(claude-statusline-mode 1)
```

### Doom Emacs

```elisp
;; In packages.el
(package! claude-statusline
  :recipe (:host github
           :repo "rz1989s/claude-code-statusline"
           :files ("ide-plugins/emacs/*.el")))

;; In config.el
(use-package! claude-statusline
  :config
  (claude-statusline-mode 1)
  ;; Optional: Add to doom-modeline
  (after! doom-modeline
    (doom-modeline-def-modeline 'main
      '(bar matches buffer-info remote-host buffer-position parrot selection-info)
      '(misc-info minor-modes input-method buffer-encoding major-mode process vcs claude-statusline checker))))
```

## Configuration

```elisp
;; Path to statusline script
(setq claude-statusline-path "~/.claude/statusline/statusline.sh")

;; Refresh interval in seconds (0 to disable)
(setq claude-statusline-refresh-interval 5)

;; Components to show
(setq claude-statusline-show-cost t)
(setq claude-statusline-show-mcp t)
(setq claude-statusline-show-repo t)

;; Custom icon
(setq claude-statusline-icon "🤖")

;; Enable async fetching (non-blocking)
(setq claude-statusline-async t)

;; Enable the mode
(claude-statusline-mode 1)
```

## Commands

| Command | Description |
|---------|-------------|
| `M-x claude-statusline-show` | Show popup with detailed metrics |
| `M-x claude-statusline-refresh` | Force refresh data |
| `M-x claude-statusline-mode` | Toggle mode-line display |

## Keybindings

```elisp
;; Suggested keybindings
(global-set-key (kbd "C-c c s") #'claude-statusline-show)
(global-set-key (kbd "C-c c r") #'claude-statusline-refresh)
```

### Popup Buffer Keys

| Key | Action |
|-----|--------|
| `q` | Close popup |
| `g` | Refresh and reload |
| `r` | Refresh and reload |

## Faces

The package defines these faces for customization:

| Face | Default | Description |
|------|---------|-------------|
| `claude-statusline-title` | Blue, bold | Section titles |
| `claude-statusline-border` | Gray | Separators |
| `claude-statusline-label` | Light gray | Field labels |
| `claude-statusline-value` | White | Field values |
| `claude-statusline-cost` | Green | Cost values |
| `claude-statusline-mcp` | Yellow | MCP info |
| `claude-statusline-clean` | Green | Clean git status |
| `claude-statusline-dirty` | Red | Dirty git status |

Customize faces:

```elisp
(set-face-attribute 'claude-statusline-title nil
                    :foreground "#ff79c6"
                    :weight 'bold)
```

## Mode-line Display

When enabled, the mode-line shows:

```
[🤖 ✓ my-project │ $0.42 │ ⚡3/5]
```

Components:
- `✓` or `●` - Git status (clean/dirty)
- Repository name
- Session cost (if > $0.00)
- MCP servers connected/total

## Doom Modeline

The package automatically registers a segment with doom-modeline:

```elisp
;; Add claude-statusline to your modeline definition
(doom-modeline-def-modeline 'main
  '(bar matches buffer-info)
  '(misc-info claude-statusline vcs checker))
```

Or use the segment function directly:

```elisp
(claude-statusline-doom-modeline-segment)
```

## API

```elisp
;; Get formatted status string
(claude-statusline--format)

;; Get raw data alist
claude-statusline--data

;; Manually refresh
(claude-statusline--refresh)

;; Doom modeline segment
(claude-statusline-doom-modeline-segment)
```

## Troubleshooting

### Package not loading

1. Verify path: `M-: (file-exists-p claude-statusline-path)`
2. Check executable: `M-! chmod +x ~/.claude/statusline/statusline.sh`
3. Test JSON: `M-! ~/.claude/statusline/statusline.sh --json`

### No data showing

1. Run `M-x claude-statusline-refresh`
2. Check `*Messages*` buffer for errors
3. Verify `claude-statusline--data` is non-nil: `M-: claude-statusline--data`

### Mode-line not updating

- Increase refresh interval or run `M-x claude-statusline-refresh`
- Enable async mode: `(setq claude-statusline-async t)`

## License

GPL-3.0
