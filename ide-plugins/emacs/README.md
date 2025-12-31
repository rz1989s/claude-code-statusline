# Claude Code Statusline - Emacs Package

Display Claude Code metrics in Emacs mode-line and popup buffers.

## Features

- **Mode-line Integration**: Real-time metrics display
- **Popup Buffer**: Detailed view with `M-x claude-statusline-show`
- **Auto-refresh**: Timer-based updates
- **Minor Mode**: Easy enable/disable

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
```

## Configuration

```elisp
;; Customize settings
(setq claude-statusline-path "~/.claude/statusline/statusline.sh")
(setq claude-statusline-refresh-interval 5)  ; seconds
(setq claude-statusline-show-cost t)
(setq claude-statusline-show-mcp t)

;; Enable the mode
(claude-statusline-mode 1)
```

## Commands

| Command | Description |
|---------|-------------|
| `M-x claude-statusline-show` | Show popup with detailed metrics |
| `M-x claude-statusline-mode` | Toggle mode-line display |

## Keybindings

```elisp
;; Suggested keybinding
(global-set-key (kbd "C-c c s") #'claude-statusline-show)
```

## Doom Emacs

```elisp
;; In packages.el
(package! claude-statusline
  :recipe (:host github
           :repo "rz1989s/claude-code-statusline"
           :files ("ide-plugins/emacs/*.el")))

;; In config.el
(use-package! claude-statusline
  :config
  (claude-statusline-mode 1))
```

## Mode-line Display

When enabled, the mode-line shows:
```
[🤖 ✓ my-project │ $0.42 │ ⚡3/5]
```

## Requirements

- Emacs 27.1+
- Claude Code Statusline installed (`~/.claude/statusline/statusline.sh`)
