;;; claude-statusline.el --- Claude Code statusline integration -*- lexical-binding: t; -*-

;; Copyright (C) 2024 The Rector

;; Author: The Rector <rector@rectorspace.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience
;; URL: https://github.com/rz1989s/claude-code-statusline

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Display Claude Code statusline metrics in Emacs.
;;
;; Features:
;; - Mode-line integration with customizable format
;; - Doom-modeline segment support
;; - Popup buffer with detailed metrics and syntax highlighting
;; - Auto-refresh with configurable interval
;; - Async data fetching option
;;
;; Usage:
;;   (require 'claude-statusline)
;;   (claude-statusline-mode 1)
;;
;; Or with use-package:
;;   (use-package claude-statusline
;;     :config (claude-statusline-mode 1))

;;; Code:

(require 'json)

;;; Customization

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
  "Refresh interval in seconds.
Set to 0 to disable auto-refresh."
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

(defcustom claude-statusline-show-repo t
  "Whether to show repository info in mode-line."
  :type 'boolean
  :group 'claude-statusline)

(defcustom claude-statusline-icon "🤖"
  "Icon to display before statusline."
  :type 'string
  :group 'claude-statusline)

(defcustom claude-statusline-async nil
  "Whether to fetch data asynchronously.
When non-nil, uses `make-process' for non-blocking updates."
  :type 'boolean
  :group 'claude-statusline)

;;; Faces

(defgroup claude-statusline-faces nil
  "Faces used by claude-statusline."
  :group 'claude-statusline
  :group 'faces)

(defface claude-statusline-title
  '((t :foreground "#89b4fa" :weight bold))
  "Face for section titles."
  :group 'claude-statusline-faces)

(defface claude-statusline-border
  '((t :foreground "#6c7086"))
  "Face for borders and separators."
  :group 'claude-statusline-faces)

(defface claude-statusline-label
  '((t :foreground "#a6adc8"))
  "Face for labels."
  :group 'claude-statusline-faces)

(defface claude-statusline-value
  '((t :foreground "#cdd6f4"))
  "Face for values."
  :group 'claude-statusline-faces)

(defface claude-statusline-cost
  '((t :foreground "#a6e3a1"))
  "Face for cost values."
  :group 'claude-statusline-faces)

(defface claude-statusline-mcp
  '((t :foreground "#f9e2af"))
  "Face for MCP server info."
  :group 'claude-statusline-faces)

(defface claude-statusline-clean
  '((t :foreground "#a6e3a1"))
  "Face for clean git status."
  :group 'claude-statusline-faces)

(defface claude-statusline-dirty
  '((t :foreground "#f38ba8"))
  "Face for dirty git status."
  :group 'claude-statusline-faces)

;;; Internal Variables

(defvar claude-statusline--data nil
  "Cached statusline data.")

(defvar claude-statusline--timer nil
  "Refresh timer.")

(defvar claude-statusline--process nil
  "Async fetch process.")

;;; Data Fetching

(defun claude-statusline--parse-json (output)
  "Parse JSON OUTPUT string, returning nil on error."
  (condition-case nil
      (json-read-from-string output)
    (error nil)))

(defun claude-statusline--fetch-sync ()
  "Fetch statusline JSON data synchronously."
  (when (file-executable-p claude-statusline-path)
    (let ((output (shell-command-to-string
                   (concat claude-statusline-path " --json 2>/dev/null"))))
      (claude-statusline--parse-json output))))

(defun claude-statusline--fetch-async ()
  "Fetch statusline JSON data asynchronously."
  (when (and (file-executable-p claude-statusline-path)
             (not claude-statusline--process))
    (let ((output-buffer ""))
      (setq claude-statusline--process
            (make-process
             :name "claude-statusline"
             :command (list claude-statusline-path "--json")
             :noquery t
             :connection-type 'pipe
             :filter (lambda (_proc output)
                       (setq output-buffer (concat output-buffer output)))
             :sentinel (lambda (proc _event)
                         (when (eq (process-status proc) 'exit)
                           (setq claude-statusline--process nil)
                           (let ((data (claude-statusline--parse-json output-buffer)))
                             (when data
                               (setq claude-statusline--data data)
                               (force-mode-line-update t))))))))))

(defun claude-statusline--fetch ()
  "Fetch statusline data using configured method."
  (if claude-statusline-async
      (claude-statusline--fetch-async)
    (claude-statusline--fetch-sync)))

(defun claude-statusline--refresh ()
  "Refresh cached data."
  (if claude-statusline-async
      (claude-statusline--fetch-async)
    (setq claude-statusline--data (claude-statusline--fetch-sync)))
  (force-mode-line-update t))

;;; Mode-line Formatting

(defun claude-statusline--format ()
  "Format statusline for mode-line display."
  (if claude-statusline--data
      (let* ((repo (alist-get 'repository claude-statusline--data))
             (cost (alist-get 'cost claude-statusline--data))
             (mcp (alist-get 'mcp claude-statusline--data))
             (parts '()))
        ;; Repository name
        (when claude-statusline-show-repo
          (let* ((status (alist-get 'status repo))
                 (clean-p (string= status "clean"))
                 (icon (if clean-p "✓" "●"))
                 (face (if clean-p 'claude-statusline-clean 'claude-statusline-dirty)))
            (push (propertize (format "%s %s" icon (alist-get 'name repo))
                              'face face)
                  parts)))
        ;; Cost
        (when (and claude-statusline-show-cost
                   (> (or (alist-get 'session cost) 0) 0))
          (push (propertize (format "$%.2f" (alist-get 'session cost))
                            'face 'claude-statusline-cost)
                parts))
        ;; MCP
        (when (and claude-statusline-show-mcp
                   (> (or (alist-get 'total mcp) 0) 0))
          (push (propertize (format "⚡%d/%d"
                                    (alist-get 'connected mcp)
                                    (alist-get 'total mcp))
                            'face 'claude-statusline-mcp)
                parts))
        (mapconcat #'identity (nreverse parts) " │ "))
    ""))

(defun claude-statusline-mode-line ()
  "Return mode-line string for Claude statusline."
  (let ((status (claude-statusline--format)))
    (if (string-empty-p status)
        ""
      (format " [%s %s]" claude-statusline-icon status))))

;;; Popup Buffer

(defun claude-statusline--insert-line (label value &optional face)
  "Insert a formatted line with LABEL and VALUE using FACE for value."
  (insert (propertize (format "  %-12s " label) 'face 'claude-statusline-label))
  (insert (propertize (format "%s\n" value) 'face (or face 'claude-statusline-value))))

(defun claude-statusline--insert-separator ()
  "Insert a separator line."
  (insert (propertize "  ─────────────────────────────────────\n"
                      'face 'claude-statusline-border)))

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
            ;; Header
            (insert "\n")
            (insert (propertize (format "  %s Claude Code Statusline\n"
                                        claude-statusline-icon)
                                'face 'claude-statusline-title))
            (insert (propertize (format "  Version: %s\n\n"
                                        (or (alist-get 'version data) "unknown"))
                                'face 'claude-statusline-label))
            (claude-statusline--insert-separator)

            ;; Repository section
            (insert "\n")
            (insert (propertize "  Repository\n" 'face 'claude-statusline-title))
            (let ((repo (alist-get 'repository data)))
              (claude-statusline--insert-line "Name:" (alist-get 'name repo))
              (claude-statusline--insert-line "Branch:" (alist-get 'branch repo))
              (let* ((status (alist-get 'status repo))
                     (face (if (string= status "clean")
                               'claude-statusline-clean
                             'claude-statusline-dirty)))
                (claude-statusline--insert-line "Status:" status face))
              (claude-statusline--insert-line "Commits:" (alist-get 'commits_today repo)))

            ;; Cost section
            (insert "\n")
            (claude-statusline--insert-separator)
            (insert "\n")
            (insert (propertize "  💰 Cost\n" 'face 'claude-statusline-title))
            (let ((cost (alist-get 'cost data)))
              (claude-statusline--insert-line "Session:"
                                              (format "$%.2f" (or (alist-get 'session cost) 0))
                                              'claude-statusline-cost)
              (claude-statusline--insert-line "Daily:"
                                              (format "$%.2f" (or (alist-get 'daily cost) 0))
                                              'claude-statusline-cost)
              (claude-statusline--insert-line "Weekly:"
                                              (format "$%.2f" (or (alist-get 'weekly cost) 0))
                                              'claude-statusline-cost)
              (claude-statusline--insert-line "Monthly:"
                                              (format "$%.2f" (or (alist-get 'monthly cost) 0))
                                              'claude-statusline-cost))

            ;; MCP section
            (let ((mcp (alist-get 'mcp data)))
              (when (> (or (alist-get 'total mcp) 0) 0)
                (insert "\n")
                (claude-statusline--insert-separator)
                (insert "\n")
                (insert (propertize "  ⚡ MCP Servers\n" 'face 'claude-statusline-title))
                (claude-statusline--insert-line
                 "Status:"
                 (format "%d/%d connected"
                         (alist-get 'connected mcp)
                         (alist-get 'total mcp))
                 'claude-statusline-mcp)
                (let ((servers (alist-get 'servers mcp)))
                  (when (and servers (> (length servers) 0))
                    (dolist (server (append servers nil))
                      (insert (propertize (format "    • %s\n" server)
                                          'face 'claude-statusline-value)))))))

            ;; GitHub section
            (let ((github (alist-get 'github data)))
              (when (eq (alist-get 'enabled github) t)
                (insert "\n")
                (claude-statusline--insert-separator)
                (insert "\n")
                (insert (propertize "   GitHub\n" 'face 'claude-statusline-title))
                (claude-statusline--insert-line "CI Status:"
                                                (or (alist-get 'ci_status github) "N/A"))
                (claude-statusline--insert-line "Open PRs:"
                                                (or (alist-get 'open_prs github) 0))))

            ;; Footer
            (insert "\n")
            (insert (propertize "  Press 'q' to close, 'g' to refresh\n\n"
                                'face 'claude-statusline-label)))
          (goto-char (point-min))
          (claude-statusline-popup-mode))
        (display-buffer buf '(display-buffer-pop-up-window)))
    (message "No Claude Code data available")))

;;;###autoload
(defun claude-statusline-refresh ()
  "Manually refresh Claude statusline data."
  (interactive)
  (claude-statusline--refresh)
  (message "Claude statusline refreshed"))

;;; Popup Mode

(defvar claude-statusline-popup-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'quit-window)
    (define-key map (kbd "g") #'claude-statusline-show)
    (define-key map (kbd "r") #'claude-statusline-show)
    map)
  "Keymap for `claude-statusline-popup-mode'.")

(define-derived-mode claude-statusline-popup-mode special-mode "Claude"
  "Major mode for Claude statusline popup buffer."
  (setq buffer-read-only t)
  (setq truncate-lines t))

;;; Doom Modeline Integration

(defun claude-statusline-doom-modeline-segment ()
  "Return segment string for doom-modeline."
  (let ((status (claude-statusline--format)))
    (unless (string-empty-p status)
      (concat " " claude-statusline-icon " " status " "))))

;; Register with doom-modeline if available
(with-eval-after-load 'doom-modeline
  (doom-modeline-def-segment claude-statusline
    "Claude Code statusline segment."
    (claude-statusline-doom-modeline-segment)))

;;; Minor Mode

;;;###autoload
(define-minor-mode claude-statusline-mode
  "Minor mode for Claude Code statusline integration.
When enabled, displays Claude Code metrics in the mode-line
and starts a timer for automatic refresh."
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
        ;; Initial fetch
        (claude-statusline--refresh)
        ;; Start refresh timer
        (when (> claude-statusline-refresh-interval 0)
          (setq claude-statusline--timer
                (run-with-timer 0 claude-statusline-refresh-interval
                                #'claude-statusline--refresh))))
    ;; Cleanup
    (when claude-statusline--timer
      (cancel-timer claude-statusline--timer)
      (setq claude-statusline--timer nil))
    (when claude-statusline--process
      (delete-process claude-statusline--process)
      (setq claude-statusline--process nil))))

(provide 'claude-statusline)

;;; claude-statusline.el ends here
