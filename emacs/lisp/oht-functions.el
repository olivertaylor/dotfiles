;; -*- lexical-binding: t; -*-

(defun oht/find-settings ()
  "Quickly open init.el"
  (interactive)
  (find-file "~/dot/emacs/init.el"))

(defun oht/kill-buffer-window ()
  "Kill current buffer and window, but not the last window."
  (interactive)
  (kill-buffer (current-buffer))
  (if (not (one-window-p))
          (delete-window))
  )

(defun oht/find-scratch ()
  (interactive)
  (if (string= (buffer-name) "*scratch*")
      (previous-buffer)
    (switch-to-buffer "*scratch*")))

(defun oht/mark-whole-line ()
  "Mark the entirety of the current line."
  (interactive)
  (beginning-of-line)
  (set-mark-command nil)
  (end-of-line))

(defun oht/rotate-window-split ()
  "Toggle between vertical and horizontal split."
  ;; Source: https://www.emacswiki.org/emacs/ToggleWindowSplit.
  ;; Author: Jeff Dwork
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

(defun oht/open-in-bbedit ()
  "Open current file or dir in BBEdit.
Adapted from:
URL `http://ergoemacs.org/emacs/emacs_dired_open_file_in_ext_apps.html'"
  (interactive)
  (let (($path (if (buffer-file-name) (buffer-file-name) (expand-file-name default-directory ) )))
    (message "path is %s" $path)
    (string-equal system-type "darwin")
    (shell-command (format "open -a BBEdit \"%s\"" $path))))

(defun oht/expand-to-beginning-of-visual-line ()
  "Set mark and move to beginning of visual line"
  (interactive)
  (set-mark-command nil)
  (beginning-of-visual-line)
  )
(defun oht/expand-to-end-of-visual-line ()
  "Set mark and move to end of visual line"
  (interactive)
  (set-mark-command nil)
  (end-of-visual-line)
  )

(defun oht/kill-line ()
  "Kill to end of line. This custom function is needed because
binding c-k to kill-line doesn't work due to kill-line being
remapped, so the remapped value is always executed. But calling a
custom function obviates this and allows kill-line to be called
directly. Nil is required."
  (interactive)
  (kill-line nil)
  )

(defun oht/kill-line-backward ()
  "Kill from the point to beginning of whole line"
  (interactive)
  (kill-line 0))

(defun oht/kill-visual-line-backward ()
  "Kill from the point to beginning of visual line"
  (interactive)
  (set-mark-command nil)
  (beginning-of-visual-line)
  (kill-region (region-beginning) (region-end))
  )

(defun oht/kill-region-or-char ()
  "If there's a region, kill it, if not, kill the next character."
  (interactive)
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (delete-forward-char 1 nil)))

(defun oht/toggle-line-numbers ()
  "Toggles display of line numbers. Applies to all buffers."
  (interactive)
  (if (bound-and-true-p display-line-numbers-mode)
      (global-display-line-numbers-mode -1)
    (global-display-line-numbers-mode)))

(defun oht/toggle-whitespace ()
  "Toggles display of indentation and space characters."
  (interactive)
  (if (bound-and-true-p whitespace-mode)
      (whitespace-mode -1)
    (whitespace-mode)))

(defun oht/open-line-below (arg)
  "Open a new indented line below the current one."
  (interactive "p")
  (end-of-line)
  (open-line arg)
  (next-line 1)
  (indent-according-to-mode))

(defun oht/open-line-above (arg)
  "Open a new indented line above the current one."
  (interactive "p")
  (beginning-of-line)
  (open-line arg)
  (indent-according-to-mode))

(defun oht/join-line-next ()
  (interactive)
  (join-line -1))

(defun oht/pipe-region (start end command)
  "Run shell-command-on-region interactivly replacing the region in place"
  (interactive (let (string)
                 (unless (mark)
                   (error "The mark is not set now, so there is no region"))
                 (setq string (read-from-minibuffer "Shell command on region: "
                                                    nil nil nil
                                                    'shell-command-history))
                 (list (region-beginning) (region-end)
                       string)))
  (shell-command-on-region start end command t t))

(defun oht/split-below ()
"Split horizontally and switch to that new window."
  (interactive)
  (split-window-below)
  (windmove-down))

(defun oht/split-beside ()
"Split vertically and switch to that new window."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun oht/forward-word-beginning ()
  "Go to the end of the next word."
  (interactive)
  (forward-word 2)
  (backward-word))

(defun oht/new-tab ()
  "Create new Mac-style tab

macOS follows this convention: command-N creates a new window
and command-T creates a new tab in the same window. The Mac Port
version of Emacs has functions and variables that makes following
this convention possible.

This function works by setting the new-frame behaviour to use
tabs, creating a new frame (thus, tab), then changing the setting
back to system default."
  (interactive)
  (setq mac-frame-tabbing t)
  (make-frame-command)
  (setq mac-frame-tabbing 'automatic)
  )

(defun oht/show-tab-bar ()
  "Show the tab bar, part of the Mac Port"
  (interactive)
  (mac-set-frame-tab-group-property nil :tab-bar-visible-p t)
  )
(defun oht/hide-tab-bar ()
  "Hide the tab bar, part of the Mac Port"
  (interactive)
  (mac-set-frame-tab-group-property nil :tab-bar-visible-p nil)
  )
(defun oht/show-tab-bar-overview ()
  "Show the tab bar overview, part of the Mac Port"
  (interactive)
  (mac-set-frame-tab-group-property nil :overview-visible-p t)
  )

(defun oht/org-insert-date-today ()
  "Insert today's date using standard org formatting."
  (interactive)
  (org-insert-time-stamp (current-time))
  )
(defun oht/switch-to-new-buffer ()
  "Create a new buffer named 'Untitled'."
  (interactive)
  (switch-to-buffer "Untitled")
  )
(defun oht/find-scratch ()
  "Switch to the *scratch* buffer"
  (interactive)
  (switch-to-buffer "*scratch*")
  )

(defun all-occur (rexp)
  "Search all buffers for REXP."
  (interactive "MSearch open buffers for regex: ")
  (multi-occur (buffer-list) rexp))

(defun pulse-line (&rest _)
  (interactive)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

;; From https://christiantietze.de/posts/2020/12/emacs-pulse-highlight-yanked-text/
(defun ct/yank-pulse-advice (orig-fn &rest args)
  "Pulse line when yanking"
  ;; Define the variables first
  (let (begin end)
    ;; Initialize `begin` to the current point before pasting
    (setq begin (point))
    ;; Forward to the decorated function (i.e. `yank`)
    (apply orig-fn args)
    ;; Initialize `end` to the current point after pasting
    (setq end (point))
    ;; Pulse to highlight!
    (pulse-momentary-highlight-region begin end)))
(advice-add 'yank :around #'ct/yank-pulse-advice)

(defun oht/other-window ()
  "Wrapper around other-window & pulse line."
  (interactive)
  (other-window 1)
  (pulse-line)
  )

(defun oht/delete-window ()
  "Wrapper around delete-window & pulse line."
  (interactive)
  (delete-window)
  (pulse-line)
  )

(defun oht/recenter-top-bottom ()
  "Wrapper around recenter-top-bottom & pulse line."
  (interactive)
  (recenter-top-bottom)
  (pulse-line)
  )

(defun occur-dwim ()
  "Call `occur' with a sane default.
Taken from oremacs.com. This will offer as the default candidate:
the current region (if it's active), or the current symbol."
  (interactive)
  (push (if (region-active-p)
            (buffer-substring-no-properties
             (region-beginning)
             (region-end))
          (let ((sym (thing-at-point 'symbol)))
            (when (stringp sym)
              (regexp-quote sym))))
        regexp-history)
  (call-interactively 'occur))

(defun comment-or-uncomment-region-or-line ()
    "Comments or uncomments the region or the current line if there's no active region."
    (interactive)
    (let (beg end)
        (if (region-active-p)
            (setq beg (region-beginning) end (region-end))
            (setq beg (line-beginning-position) end (line-end-position)))
        (comment-or-uncomment-region beg end)))

(provide 'oht-functions)