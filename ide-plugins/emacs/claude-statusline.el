;;; claude-statusline.el --- Claude Code statusline integration -*- lexical-binding: t; -*-

;; Copyright (C) 2024 The Rector

;; Author: The Rector <rector@rectorspace.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (json "1.5"))
;; Keywords: tools, convenience
;; URL: https://github.com/rz1989s/claude-code-statusline

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Display Claude Code statusline metrics in Emacs.
;;
;; Features:
;; - Mode-line integration
;; - Popup buffer with detailed metrics
;; - Auto-refresh with configurable interval
;;
;; Usage:
;;   (require 'claude-statusline)
;;   (claude-statusline-mode 1)

;;; Code:

(require 'json)

(defgroup claude-statusline nil
  "Claude Code statusline integration."
  :group 'tools
  :prefix "claude-statusline-")

(defcustom claude-statusline-path
  (expand-file-name "~/.claude/statusline/statusline.sh")
  "Path to the statusline.sh script."
  :type 'string
  :group 'claude-statusline)

(defcustom claude-statusline-refresh-interval 5
  "Refresh interval in seconds."
  :type 'integer
  :group 'claude-statusline)

(defcustom claude-statusline-show-cost t
  "Whether to show session cost in mode-line."
  :type 'boolean
  :group 'claude-statusline)

(defcustom claude-statusline-show-mcp t
  "Whether to show MCP server count in mode-line."
  :type 'boolean
  :group 'claude-statusline)

(defvar claude-statusline--data nil
  "Cached statusline data.")

(defvar claude-statusline--timer nil
  "Refresh timer.")

(defun claude-statusline--fetch ()
  "Fetch statusline JSON data."
  (when (file-executable-p claude-statusline-path)
    (let ((output (shell-command-to-string
                   (concat claude-statusline-path " --json 2>/dev/null"))))
      (condition-case nil
          (json-read-from-string output)
        (error nil)))))

(defun claude-statusline--refresh ()
  "Refresh cached data."
  (setq claude-statusline--data (claude-statusline--fetch))
  (force-mode-line-update t))

(defun claude-statusline--format ()
  "Format statusline for mode-line display."
  (if claude-statusline--data
      (let* ((repo (alist-get 'repository claude-statusline--data))
             (cost (alist-get 'cost claude-statusline--data))
             (mcp (alist-get 'mcp claude-statusline--data))
             (parts '()))
        ;; Repository name
        (let ((status-icon (if (string= (alist-get 'status repo) "clean")
                               "✓" "●")))
          (push (format "%s %s" status-icon (alist-get 'name repo)) parts))
        ;; Cost
        (when claude-statusline-show-cost
          (push (format "$%.2f" (alist-get 'session cost)) parts))
        ;; MCP
        (when (and claude-statusline-show-mcp
                   (> (alist-get 'total mcp) 0))
          (push (format "⚡%d/%d"
                        (alist-get 'connected mcp)
                        (alist-get 'total mcp))
                parts))
        (mapconcat #'identity (nreverse parts) " │ "))
    ""))

(defun claude-statusline-mode-line ()
  "Return mode-line string for Claude statusline."
  (let ((status (claude-statusline--format)))
    (if (string-empty-p status)
        ""
      (format " [🤖 %s]" status))))

;;;###autoload
(defun claude-statusline-show ()
  "Show Claude Code statusline details in a popup buffer."
  (interactive)
  (claude-statusline--refresh)
  (if claude-statusline--data
      (let ((buf (get-buffer-create "*Claude Statusline*"))
            (data claude-statusline--data))
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert "╭─────────────────────────────────────╮\n")
            (insert "│     Claude Code Statusline          │\n")
            (insert (format "│           v%-24s│\n"
                            (alist-get 'version data)))
            (insert "├─────────────────────────────────────┤\n")
            (insert "│ Repository                          │\n")
            (let ((repo (alist-get 'repository data)))
              (insert (format "│   Name:    %-25s│\n" (alist-get 'name repo)))
              (insert (format "│   Branch:  %-25s│\n" (alist-get 'branch repo)))
              (insert (format "│   Status:  %-25s│\n" (alist-get 'status repo)))
              (insert (format "│   Commits: %-25s│\n"
                              (alist-get 'commits_today repo))))
            (insert "├─────────────────────────────────────┤\n")
            (insert "│ Cost                                │\n")
            (let ((cost (alist-get 'cost data)))
              (insert (format "│   Session: $%-24.2f│\n" (alist-get 'session cost)))
              (insert (format "│   Daily:   $%-24.2f│\n" (alist-get 'daily cost)))
              (insert (format "│   Weekly:  $%-24.2f│\n" (alist-get 'weekly cost)))
              (insert (format "│   Monthly: $%-24.2f│\n" (alist-get 'monthly cost))))
            (insert "├─────────────────────────────────────┤\n")
            (insert "│ MCP Servers                         │\n")
            (let ((mcp (alist-get 'mcp data)))
              (insert (format "│   Connected: %-23s│\n"
                              (format "%d/%d"
                                      (alist-get 'connected mcp)
                                      (alist-get 'total mcp)))))
            (insert "╰─────────────────────────────────────╯\n")
            (insert "\nPress 'q' to close.\n"))
          (goto-char (point-min))
          (special-mode)
          (local-set-key (kbd "q") #'quit-window))
        (display-buffer buf))
    (message "No Claude Code data available")))

;;;###autoload
(define-minor-mode claude-statusline-mode
  "Minor mode for Claude Code statusline integration."
  :global t
  :lighter nil
  :group 'claude-statusline
  (if claude-statusline-mode
      (progn
        ;; Add to mode-line
        (unless (member '(:eval (claude-statusline-mode-line)) mode-line-format)
          (setq-default mode-line-format
                        (append mode-line-format
                                '((:eval (claude-statusline-mode-line))))))
        ;; Start refresh timer
        (claude-statusline--refresh)
        (setq claude-statusline--timer
              (run-with-timer 0 claude-statusline-refresh-interval
                              #'claude-statusline--refresh)))
    ;; Stop timer
    (when claude-statusline--timer
      (cancel-timer claude-statusline--timer)
      (setq claude-statusline--timer nil))))

(provide 'claude-statusline)

;;; claude-statusline.el ends here
