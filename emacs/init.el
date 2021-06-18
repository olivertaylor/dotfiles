;;; init.el --- Oliver Taylor's Emacs Config -*- lexical-binding: t -*-

;; Copyright (C) 2021 Oliver Taylor

;; Author: Oliver Taylor
;; Homepage: https://github.com/olivertaylor/dotfiles


;;; Commentary:

;; This file has an outline which can be viewed by looking at comments
;; starting with three or more semicolons. `outline-minor-mode' supports this
;; convention by default and helps with navigation. You can also create an
;; occur buffer with the search [^;;;+].


;;; Configuration

;;;; Variables

(when (eq system-type 'darwin)
  (cd "~/home")
  (defvar oht-dotfiles "~/home/dot/emacs/")
  (defvar oht-orgfiles "~/home/org/")
  (defvar user-downloads-directory "~/Downloads"))

(when (eq system-type 'windows-nt)
  (cd "~/")
  (defvar oht-dotfiles "~/.emacs.d/")
  (defvar oht-orgfiles "~/home/org/")
  (defvar user-downloads-directory "~/home/Downloads"))


;;;; Settings

;; Save all interactive customization to a temp file, which is never loaded.
;; This means interactive customization is session-local. Only this init file persists sessions.
(setq custom-file (make-temp-file "emacs-custom-"))

;; For most of my "settings" I use custom-set-variables, which does a bunch of neat stuff.
;; First, it calls a variable's "setter" function, if it has one.
;; Second, it can activate modes as well as set variables.
;; Third, it handles setting buffer-local variables correctly.
;; https://with-emacs.com/posts/tutorials/almost-all-you-need-to-know-about-variables/#_user_options
;; https://old.reddit.com/r/emacs/comments/exnxha/withemacs_almost_all_you_need_to_know_about/fgadihl/

(custom-set-variables
 '(inhibit-startup-screen t)
 '(global-auto-revert-mode t)
 '(save-place-mode t)
 '(recentf-mode t)
 '(winner-mode t)
 '(show-paren-mode t)
 '(blink-cursor-mode t)
 '(cursor-type '(bar . 3))
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(minibuffer-depth-indicate-mode t)
 '(ring-bell-function 'ignore)
 '(set-language-environment "UTF-8")
 '(frame-title-format '("%b"))
 '(uniquify-buffer-name-style 'forward)
 '(vc-follow-symlinks t)
 '(find-file-visit-truename t)
 '(create-lockfiles nil)
 '(make-backup-files nil)
 '(load-prefer-newer t)
 '(bookmark-save-flag 1)
 ;;'(bookmark-menu-confirm-deletion t)
 '(word-wrap t)
 '(truncate-lines t)
 '(delete-by-moving-to-trash t)
 '(confirm-kill-processes nil)
 '(save-interprogram-paste-before-kill t)
 '(kill-do-not-save-duplicates t)
 '(split-window-keep-point nil)
 '(sentence-end-double-space nil)
 '(set-mark-command-repeat-pop t)
 '(mark-even-if-inactive nil)
 '(tab-width 4)
 '(indent-tabs-mode nil)
 '(fill-column 78))

(when (eq system-type 'darwin)
  (setq locate-command "mdfind"
        trash-dircetory "~/.Trash"))

;; Mode Line
(custom-set-variables
 '(display-time-format " %Y-%m-%d  %H:%M")
 '(display-time-interval 60)
 '(display-time-default-load-average nil)
 '(column-number-mode t)
 '(display-time-mode t))

;; Include battery in mode-line on laptop
(when (string= (system-name) "shadowfax.local")
  (custom-set-variables
   '(display-battery-mode t)
   '(battery-mode-line-format " [%b%p%%]")))


;;;; Functions

(defun toggle-window-split ()
  "Toggle window split from vertical to horizontal."
  (interactive)
  (if (> (length (window-list)) 2)
      (error "Can't toggle with more than 2 windows.")
    (let ((was-full-height (window-full-height-p)))
      (delete-other-windows)
      (if was-full-height
          (split-window-vertically)
        (split-window-horizontally))
      (save-selected-window
        (other-window 1)
        (switch-to-buffer (other-buffer))))))

(defun macos-open-file ()
  "Open the file inferred by ffap using `open'."
  (interactive)
  (if-let* ((file? (ffap-guess-file-name-at-point))
            (file (expand-file-name file?)))
      (progn
        (message "Opening %s..." file)
        (call-process "open" nil 0 nil file))
    (message "No file found at point.")))

(defun kill-to-beg-line ()
  "Kill from point to the beginning of the line."
  (interactive)
  (kill-line 0))

(defun pipe-region (start end command)
  ;; https://github.com/oantolin/emacs-config/blob/master/my-lisp/text-extras.el
  "Pipe region through shell command. If the mark is inactive,
pipe whole buffer."
  (interactive (append
                (if (use-region-p)
                    (list (region-beginning) (region-end))
                  (list (point-min) (point-max)))
                (list (read-shell-command "Pipe through: "))))
  (let ((exit-status (call-shell-region start end command t t)))
    (unless (equal 0 exit-status)
      (let ((error-msg (string-trim-right (buffer-substring (mark) (point)))))
        (undo)
        (cond
         ((null exit-status)
          (message "Unknown error"))
         ((stringp exit-status)
          (message "Signal %s" exit-status))
         (t
          (message "[%d] %s" exit-status error-msg)))))))

(defun find-file-recursively ()
  "Find Files Recursively using completing read."
  (interactive)
  (find-file (completing-read "Find File Recursively: "
                              (directory-files-recursively default-directory ".+"))))

(defun comment-or-uncomment-region-dwim ()
  "Toggle comment for region, or line."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

(defun mark-whole-line ()
  "Put the point at end of this whole line, mark at beginning"
  (interactive)
  (beginning-of-line)
  (set-mark-command nil)
  (end-of-line))

(defun narrow-or-widen-dwim (p)
  ;; https://github.com/oantolin/emacs-config/blob/master/my-lisp/narrow-extras.el
  "Widen if buffer is narrowed, narrow-dwim otherwise.
Dwim means: region, org-src-block, org-subtree, or defun,
whichever applies first. Narrowing to org-src-block actually
calls `org-edit-src-code'.
With prefix P, don't widen, just narrow even if buffer is
already narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((and (bound-and-true-p org-src-mode) (not p))
         (org-edit-src-exit))
        ((region-active-p)
         (narrow-to-region (region-beginning) (region-end)))
        ((derived-mode-p 'org-mode)
         (or (ignore-errors (org-edit-src-code))
             (ignore-errors (org-narrow-to-block))
             (org-narrow-to-subtree)))
        ((derived-mode-p 'latex-mode)
         (LaTeX-narrow-to-environment))
        ((derived-mode-p 'tex-mode)
         (TeX-narrow-to-group))
        (t (narrow-to-defun))))

(defun find-emacs-dotfiles ()
  "Find lisp files in your Emacs dotfiles directory, pass to completing-read."
  (interactive)
  (find-file (completing-read "Find Elisp Dotfile: "
                              (directory-files-recursively oht-dotfiles "\.el$"))))

(defun find-org-files ()
  "Find org files in your org directory, pass to completing-read."
  (interactive)
  (find-file (completing-read "Find Org Files: "
                              (directory-files-recursively oht-orgfiles "\.org$"))))

(defun find-user-init-file ()
  "Find the user-init-file"
  (interactive)
  (find-file user-init-file))

(defun exchange-point-and-mark-dwim ()
  "Respect region active/inactive and swap point and mark.
If a region is active, then leave it activated and swap point and mark.
If no region is active, then just swap point and mark."
  (interactive)
  (if (use-region-p)
      (exchange-point-and-mark)
    (exchange-point-and-mark)
    (deactivate-mark nil)))

(defun push-mark-no-activate ()
  "Pushes `point' to `mark-ring' and does not activate the region
   Equivalent to \\[set-mark-command] when \\[transient-mark-mode] is disabled"
  (interactive)
  (push-mark (point) t nil)
  (message "Pushed mark to ring"))

(when (eq system-type 'darwin)
  (setq youtube-dl-path "/usr/local/bin/youtube-dl")
  (setq youtube-dl-output-dir "~/Downloads/"))

(defun youtube-dl-URL-at-point ()
  "Send the URL at point to youtube-dl."
  (interactive)
  (async-shell-command (format "%s -o \"%s%s\" -f best \"%s\""
                               youtube-dl-path
                               youtube-dl-output-dir
                               "%(title)s.%(ext)s"
                               (ffap-url-at-point))))

(defun org-insert-date-today ()
  "Insert today's date using standard org formatting."
  (interactive)
  (insert (format-time-string "<%Y-%m-%d %a>")))

(defun org-insert-date-today-inactive ()
  "Inserts today's date in org inactive format."
  (interactive)
  (insert (format-time-string "\[%Y-%m-%d %a\]")))

;; Dispatch Functions -- I use these to launch frequently-used stuff
(defun oht-dispatch-downloads () (interactive) (find-file "~/Downloads"))
(defun oht-dispatch-reading () (interactive) (find-file "~/Downloads/reading"))
(defun oht-dispatch-watch () (interactive) (find-file "~/Downloads/watch"))
(defun oht-dispatch-google-news () (interactive) (browse-url "http://68k.news/"))


;;; Keybindings

;;;; Modifiers

;; If on a Mac, use the command key as Super, left-option for Meta, and
;; right-option for Alt.
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super
        mac-option-modifier 'meta
        mac-right-command-modifier 'meta
        mac-right-option-modifier 'nil))

;; If on Windows, use Windows key as Super
(when (eq system-type 'windows-nt)
  (setq w32-pass-lwindow-to-system nil)
  (setq w32-lwindow-modifier 'super)
  (w32-register-hot-key [s-]))


;;;; Bosskey Mode

;; Minor modes override global bindings, so any bindings you don't want
;; overridden should be placed in a minor mode. This technique is stolen from
;; the package bind-key.

(defvar bosskey-mode-map (make-keymap)
  "Keymap for bosskey-mode.")

(define-minor-mode bosskey-mode
  "Minor mode for my personal keybindings, which override others.
The only purpose of this minor mode is to override global keybindings.
Keybindings you define here will take precedence."
  :init-value t
  :global t
  :keymap bosskey-mode-map)

(add-to-list 'emulation-mode-map-alists
             `((bosskey-mode . ,bosskey-mode-map)))

(defmacro boss-key (key command)
  "Defines a key binding for bosskey-mode."
  `(define-key bosskey-mode-map (kbd ,key) ,command))

(defmacro boss-keys (&rest body)
  ;; https://github.com/kerbyfc/dotmacs/blob/master/bindings/bindings.el
  "Defines multiple key bindings for bosskey-mode.
Accepts CONS where CAR is a key in string form, to be passed to `kbd', and CADR is a command."
  `(progn
     ,@(cl-loop for binding in body
                collect
                `(let ((key ,(car binding))
                       (def ,(cadr binding)))
                   (define-key bosskey-mode-map (kbd key) def)))))


;;;; Actual Keybindings

(define-key key-translation-map (kbd "ESC") (kbd "C-g"))

;; Mac-like bindings
(when (eq system-type 'darwin)
  (boss-keys
   ("s-q"       'save-buffers-kill-terminal)
   ("s-m"       'iconify-frame)
   ("s-n"       'make-frame-command)
   ("s-s"       'save-buffer)
   ("s-,"       'find-user-init-file)
   ("s-o"       'find-file)
   ("s-z"       'undo-fu-only-undo)
   ("s-Z"       'undo-fu-only-redo)
   ("s-x"       'kill-region)
   ("s-c"       'kill-ring-save)
   ("s-v"       'yank)
   ("s-<left>"  'beginning-of-visual-line)
   ("s-<right>" 'end-of-visual-line)
   ("s-<up>"    'beginning-of-buffer)
   ("s-<down>"  'end-of-buffer)))

;; Personal keybindings
(boss-keys
 ("C-<return>" 'oht-transient-general)
 ("M-["        'previous-buffer)
 ("M-]"        'next-buffer)
 ("M-o"        'other-window)
 ("M-."        'embark-act)
 ("M-'"        'hippie-expand)
 ("M-c"        'capitalize-dwim)
 ("M-l"        'downcase-dwim)
 ("M-u"        'upcase-dwim)
 ("M-\\"       'cycle-spacing)
 ("M-z"        'zap-up-to-char)
 ("C-x C-x"    'exchange-point-and-mark-dwim)
 ("C-x C-b"    'ibuffer-other-window)
 ("C-x C-n"    'make-frame-command)
 ("C-x C-,"    'find-user-init-file)
 ("M-g ."      'xref-find-definitions)
 ("M-0"        'delete-window)
 ("M-1"        'delete-other-windows)
 ("M-2"        'split-window-below)
 ("M-3"        'split-window-right)
 ("M-4"        'undefined)
 ("M-5"        'undefined)
 ("M-6"        'undefined)
 ("M-7"        'undefined)
 ("M-8"        'undefined)
 ("M-9"        'undefined)
 ("M--"        'undefined))


;;;; Mouse

;; Gasp! An Emacs user that actually uses the mouse?! Scandalous.

;; Start by making shift-click extend the selection (region)
(global-set-key [S-down-mouse-1] 'ignore)
(global-set-key [S-mouse-1] 'mouse-save-then-kill)

;; The below bindings are taken directly from the source of `mouse.el'
;; but I've swapped the modifier keys. This makes more sense to me.

;; Use M-drag-mouse-1 to create rectangle regions
(global-set-key [M-down-mouse-1] #'mouse-drag-region-rectangle)
(global-set-key [M-drag-mouse-1] #'ignore)
(global-set-key [M-mouse-1]      #'mouse-set-point)

;; Use C-M-drag-mouse-1 to create secondary selections
(global-set-key [C-M-mouse-1]      'mouse-start-secondary)
(global-set-key [C-M-drag-mouse-1] 'mouse-set-secondary)
(global-set-key [C-M-down-mouse-1] 'mouse-drag-secondary)


;;; Package Management

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(setq package-archive-priorities '(("gnu" . 20)("melpa" . 10)))

(setq package-selected-packages
      '(bicycle
        buffer-move
        consult
        embark
        embark-consult
        fountain-mode
        helpful
        isearch-mb
        marginalia
        markdown-mode
        modus-themes
        move-text
        olivetti
        orderless
        selected
        transient
        undo-fu
        unfill
        vertico
        visual-regexp
        visual-regexp-steroids
        blackout
        lua-mode
        use-package))

(when (string= (system-name) "shadowfax.local")
  (add-to-list 'package-selected-packages 'elfeed))

(when (eq system-type 'darwin)
  (add-to-list 'package-selected-packages 'magit))

;; Install packages with `package-install-selected-packages', remove packages
;; with `package-autoremove'. Both functions look at the variable
;; `package-selected-packages' for the canonical list of packages.

;; You can automatically remove anything not in `package-selected-packages'
;; (thus not in this init file) by un-commenting this hook:
;; (add-hook 'emacs-startup-hook 'package-autoremove)

;; Use-Package, Blackout, Transient
;; This config requires these 3 packages to run properly.

(eval-when-compile
  (require 'use-package))

(setq use-package-always-defer t
      use-package-hook-name-suffix nil)

(autoload 'blackout "blackout" nil t)
(autoload 'transient-define-prefix "transient" nil t)

(blackout 'eldoc-mode)
(blackout 'emacs-lisp-mode "Elisp")
(blackout 'auto-fill-function " Fill")


;;; Built-In Packages & Lisp

;;;; Flyspell

(add-hook 'text-mode-hook 'turn-on-flyspell)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(with-eval-after-load 'flyspell

  (blackout 'flyspell-mode " Spell")

  (transient-define-prefix flyspell-mode-transient ()
    "Transient for a spelling interface"
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Toggle Modes"
      ("m" "Flyspell" flyspell-mode)
      ("M" "Prog Flyspell" flyspell-prog-mode)]
     ["Check"
      ("b" "Buffer" flyspell-buffer)
      ("r" "Region" flyspell-region)]
     ["Correction"
      ("n" "Next" flyspell-goto-next-error)
      ("<return>" "Fix" ispell-word)
      ("<SPC>" "Auto Fix" flyspell-auto-correct-word)
      ("<DEL>" "Delete Word" kill-word)
      ("C-/" "Undo" undo-fu-only-undo)
      ("M-/" "Redo" undo-fu-only-redo)]])

  ) ; end flyspell


;;;; Facedancer Mode

;; Facedancer's goal is to make customizing Emacs' fonts easy.
;; facedancer-font-set allows you to set the global fonts.
;; facedancer-mode allows you to set per-buffer fonts.
;; facedancer-vadjust-mode allows optical adjustment of the variable-pitch height.


;;;;; Variables

(defvar facedancer-monospace "Courier"
  "Monospace font to be used for the default and fixed-pitch faces.")

(defvar facedancer-variable "Georgia"
  "Variable font to to used for the variable-pitch face.")

(defvar facedancer-monospace-size 12
  "Font size, as an integer, to be used for the default and fixed-pitch sizes.

This value will be multiplied by 10, so 12 will become 120. This is to comply
with Emacs' set-face-attribute requirements.")

(defvar facedancer-variable-size 14
  "Font point size, as an integer, to be used for the variable-pitch size.

This value will be used to determine a relative (float) size based on the size
of facedancer-monospace. So if your monospace size is 12 and your variable size
is 14 the derived size will be 1.16.")

(defvar facedancer-monospace-weight 'normal
  "Weight of both the default and fixed-pitch faces.")

(defvar facedancer-variable-weight 'normal
  "Weight of the variable-pitch face.")

(defvar facedancer-monospace-width 'normal
  "Width of both the default and fixed-pitch faces.")

(defvar facedancer-variable-width 'normal
  "Width of the variable-pitch face.")


;;;;; Functions

(defun facedancer-line-spacing (&optional arg)
  "Interactive wrapper around line-spacing var. Takes an argument, 0 by default."
  (interactive "P")
  (setq-local line-spacing arg))

(defun facedancer-font-set ()
  "Function for globally setting the default, variable-, and fixed-pitch faces.

All three faces will be set to exactly the same size, with the variable-
and fixed-pitch faces as relative (float) sizes. This allows
text-scale-adjust to work correctly."
  (interactive)
  (set-face-attribute 'default nil
                      :family facedancer-monospace
                      :weight facedancer-monospace-weight
                      :width  facedancer-monospace-width
                      :height (* facedancer-monospace-size 10))
  (set-face-attribute 'fixed-pitch nil
                      :family facedancer-monospace
                      :weight facedancer-monospace-weight
                      :width  facedancer-monospace-width
                      :height 1.0)
  (set-face-attribute 'variable-pitch nil
                      :family facedancer-variable
                      :weight facedancer-variable-weight
                      :width  facedancer-variable-width
                      :height 1.0))


;;;;; Facedancer Mode

;; There are a number of built-in functions for dealing with setting
;; per-buffer fonts, but all of them are built on buffer-face-mode, which
;; works by remapping ONLY the default face to a new value. If you'd like to
;; remap specific faces (for example the variable-pitch face)
;; buffer-face-mode won't cut it. The below approach applies the exact same
;; approach as buffer-face-mode but allows you to target individual faces.

(define-minor-mode facedancer-mode
  "Local minor mode for setting custom fonts per buffer.

Reads the following variables, all are optional.

VARIABLE                      DEFAULT VALUE
---------------------------   -------------
facedancer-monospace          Monaco
facedancer-variable           Georgia
facedancer-monospace-size     12
facedancer-variable-size      14
facedancer-monospace-weight   normal
facedancer-variable-weight    normal
facedancer-monospace-width    normal
facedancer-variable-width     normal

To use, create a function which sets the variables locally, then
call that function with a hook, like so:

    (defun my/custom-elfeed-fonts ()
      (setq-local facedancer-monospace \"Iosevka\"
                  facedancer-variable  \"Inter\")
      (facedancer-mode 'toggle))

    (add-hook 'elfeed-show-mode 'my/custom-elfeed-fonts)"
  :init-value nil
  :lighter " FaceD"
  (if facedancer-mode
      (progn
        (setq-local facedancer-default-remapping
                    (face-remap-add-relative 'default
                                             :family facedancer-monospace
                                             :weight facedancer-monospace-weight
                                             :width  facedancer-monospace-width
                                             :height (/ (float facedancer-monospace-size)
                                                        (float facedancer-variable-size))))
        (setq-local facedancer-fixed-pitch-remapping
                    (face-remap-add-relative 'fixed-pitch
                                             :family facedancer-monospace
                                             :weight facedancer-monospace-weight
                                             :width  facedancer-monospace-width
                                             :height (/ (float facedancer-monospace-size)
                                                        (float facedancer-variable-size))))
        (setq-local facedancer-variable-pitch-remapping
                    (face-remap-add-relative 'variable-pitch
                                             :family facedancer-variable
                                             :weight facedancer-variable-weight
                                             :width  facedancer-variable-width
                                             :height (/ (float facedancer-variable-size)
                                                        (float facedancer-monospace-size))))
        (force-window-update (current-buffer)))
    (progn
      (face-remap-remove-relative facedancer-default-remapping)
      (face-remap-remove-relative facedancer-fixed-pitch-remapping)
      (face-remap-remove-relative facedancer-variable-pitch-remapping)
      (force-window-update (current-buffer)))))


;;;;; Facedancer Variable Adjust Mode

(define-minor-mode facedancer-vadjust-mode
  "Minor mode to adjust the variable-pitch face size buffer-locally.

A minor mode to scale (in the current buffer) the variable-pitch
face up to the height defined by ‘facedancer-variable-size’ and
the fixed-pitch face down to the height defined by
‘facedancer-monospace-size’."
  :init-value nil
  :lighter " V+"
  (if facedancer-vadjust-mode
      (progn
        (setq-local variable-pitch-remapping
                    (face-remap-add-relative 'variable-pitch
                                             :height (/ (float facedancer-variable-size)
                                                        (float facedancer-monospace-size))))
        (setq-local fixed-pitch-remapping
                    (face-remap-add-relative 'fixed-pitch
                                             :height (/ (float facedancer-monospace-size)
                                                        (float facedancer-variable-size))))
        (force-window-update (current-buffer)))
    (progn
      (face-remap-remove-relative variable-pitch-remapping)
      (face-remap-remove-relative fixed-pitch-remapping)
      (force-window-update (current-buffer)))))

;; Add a hook which enables facedancer-vadjust-mode when buffer-face-mode
;; activates.
(add-hook 'buffer-face-mode-hook (lambda () (facedancer-vadjust-mode 'toggle)))


;;;; Secondary Selection

;; Emacs's Secondary Selection assumes you only want to interact with it via
;; the mouse, however it is perfectly possible to do it via the keyboard, all
;; you need is some wrapper functions to make things keybinding-addressable.

(defun oht/cut-secondary-selection ()
  "Cut the secondary selection."
  (interactive)
  (mouse-kill-secondary))

(defun oht/copy-secondary-selection ()
  "Copy the secondary selection."
  (interactive)
  ;; there isn't a keybinding-addressable function to kill-ring-save
  ;; the 2nd selection so here I've made my own. This is extracted
  ;; directly from 'mouse.el:mouse-secondary-save-then-kill'
  (kill-new
   (buffer-substring (overlay-start mouse-secondary-overlay)
                     (overlay-end mouse-secondary-overlay))
   t))

(defun oht/cut-secondary-selection-paste ()
  "Cut the secondary selection and paste at point."
  (interactive)
  (mouse-kill-secondary)
  (yank))

(defun oht/copy-secondary-selection-paste ()
  "Copy the secondary selection and paste at point."
  (interactive)
  (oht/copy-secondary-selection)
  (yank))

(defun oht/mark-region-as-secondary-selection ()
  "Make the region the secondary selection."
  (interactive)
  (secondary-selection-from-region))

(defun oht/mark-secondary-selection ()
  "Mark the Secondary Selection as the region."
  (interactive)
  (secondary-selection-to-region))

(defun oht/delete-secondary-selection ()
  "Delete the Secondary Selection."
  (interactive)
  (delete-overlay mouse-secondary-overlay))

(transient-define-prefix oht-transient-2nd ()
  "Transient for working with the secondary selection"
  [["Cut/Copy"
    ("xx" "Cut 2nd" oht/cut-secondary-selection)
    ("cc" "Copy 2nd" oht/copy-secondary-selection)]
   ["& Paste"
    ("xv" "Cut 2nd & Paste" oht/cut-secondary-selection-paste)
    ("cv" "Copy 2nd & Paste" oht/copy-secondary-selection-paste)]
   ["Mark"
    ("m"  "Mark Region as 2nd" oht/mark-region-as-secondary-selection)
    ("g"  "Make 2nd the Region" oht/mark-secondary-selection)
    ("d"  "Delete 2nd" oht/delete-secondary-selection)]])


;;;; Minibuffer

(custom-set-variables
 '(enable-recursive-minibuffers t)
 '(savehist-mode t)
 '(completion-show-help nil)
 '(resize-mini-windows t))

;; The completions list itself is read-only, so why not allow some nice navigation?
(define-key completion-list-mode-map (kbd "n") 'next-completion)
(define-key completion-list-mode-map (kbd "p") 'previous-completion)

;; I want to use my usual other-window binding to switch between the
;; minibuffer and the completions list. There is a built-in
;; `switch-to-completions' but it doesn't support Embark or fall-back to
;; `other-window', so I made my own.
(defun switch-to-completions-or-other-window ()
  "Switch to the completions window, if it exists, or another window."
  (interactive)
  (if (get-buffer-window "*Embark Collect Completions*")
      (select-window (get-buffer-window "*Embark Collect Completions*"))
    (if (get-buffer-window "*Completions*")
        (progn
          (select-window (get-buffer-window "*Completions*"))
          (when (bobp) (next-completion 1)))
      (other-window 1))))

(defun switch-to-minibuffer ()
  "Focus the active minibuffer.
Bind this to `completion-list-mode-map' to M-v to easily jump
between the list of candidates present in the \\*Completions\\*
buffer and the minibuffer (because by default M-v switches to the
completions if invoked from inside the minibuffer."
  (interactive)
  (let ((mini (active-minibuffer-window)))
    (when mini
      (select-window mini))))

(define-key minibuffer-local-completion-map (kbd "M-o") 'switch-to-completions-or-other-window)
(define-key completion-list-mode-map (kbd "M-o") 'switch-to-minibuffer)


;;;; Isearch

(setq search-whitespace-regexp ".*?")
(setq isearch-lax-whitespace t)
(setq isearch-lazy-count t)

(defun isearch-exit-at-start ()
  "Exit search at the beginning of the current match."
  (when (and isearch-forward
             (number-or-marker-p isearch-other-end)
             (not isearch-mode-end-hook-quit))
    (goto-char isearch-other-end)))

(add-hook 'isearch-mode-end-hook 'isearch-exit-at-start)

;; isearch-mb allows you to edit the isearch in the minibuffer. Lovely.
(isearch-mb-mode)

;; Quit isearch when calling occur
(add-to-list 'isearch-mb--after-exit #'occur)

;;;; Outline

;; `outline' provides major and minor modes for collapsing sections of a
;; buffer into an outline-like format. Let's turn that minor mode into a
;; global minor mode and enable it.
(define-globalized-minor-mode global-outline-minor-mode
  outline-minor-mode outline-minor-mode)
(global-outline-minor-mode +1)

(blackout 'outline-minor-mode)


;;;; Pulse

(defun pulse-line (&rest _)
  "Interactive function to pulse the current line."
  (interactive)
  (pulse-momentary-highlight-one-line (point)))

(defun ct/yank-pulse-advice (orig-fn &rest args)
  "Pulse line when yanking"
  ;; From https://christiantietze.de/posts/2020/12/emacs-pulse-highlight-yanked-text/
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

(defadvice other-window (after other-window-pulse activate) (pulse-line))
(defadvice delete-window (after delete-window-pulse activate) (pulse-line))
(defadvice recenter-top-bottom (after recenter-top-bottom-pulse activate) (pulse-line))

(advice-add 'yank :around #'ct/yank-pulse-advice)


;;;; Remember Mode

(custom-set-variables
 '(remember-data-file (concat oht-orgfiles "remember-notes"))
 '(remember-notes-initial-major-mode 'fundamental-mode)
 '(remember-notes-auto-save-visited-file-name t))

(defun remember-dwim ()
  "If the region is active, capture with region, otherwise just capture."
  (interactive)
  (if (use-region-p)
      (let ((current-prefix-arg 4)) (call-interactively 'remember))
    (remember)))


;;;; iBuffer

(with-eval-after-load 'ibuffer

  (setq ibuffer-show-empty-filter-groups nil)

  (setq ibuffer-saved-filter-groups
        '(("default"
           ("Read"  (or (mode . eww-mode)
                        (mode . elfeed-search-mode)
                        (mode . elfeed-show-mode)))
           ("Org"   (or (mode . org-mode)
                        (mode . org-agenda-mode)))
           ("Dired" (mode . dired-mode))
           ("ELisp" (mode . emacs-lisp-mode))
           ("Help"  (or (name . "\*Help\*")
                        (name . "\*Apropos\*")
                        (name . "\*Info\*"))))))

  (defun oht-ibuffer-hook ()
    (hl-line-mode 1)
    (ibuffer-auto-mode 1)
    (ibuffer-switch-to-saved-filter-groups "default"))

  (add-hook 'ibuffer-mode-hook 'oht-ibuffer-hook)

  ) ; End ibuffer


;;;; Hippie Expand

(setq hippie-expand-try-functions-list
      '(try-complete-file-name-partially
        try-complete-file-name
        try-expand-line
        try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol))


;;;; Dired

(with-eval-after-load 'dired

  (setq dired-use-ls-dired nil) ; no more warning message

  (defun dired-open-file ()
    "In dired, open the file named on this line using the 'open' shell command."
    (interactive)
    (let* ((file (dired-get-filename nil t)))
      (message "Opening %s..." file)
      (call-process "open" nil 0 nil file)
      (message "Opening %s done" file)))

  (define-key dired-mode-map (kbd "O") 'dired-open-file)
  (define-key dired-mode-map (kbd "C-/") 'dired-undo)

  (add-hook 'dired-mode-hook
            (lambda ()
              (dired-hide-details-mode 1)
              (auto-revert-mode)
              (hl-line-mode 1)))

  ) ; End dired config


;;; Appearance

(use-package modus-themes
  :custom
  (modus-themes-slanted-constructs t)
  (modus-themes-links 'faint-neutral-underline)
  (modus-themes-mode-line 'accented)
  (modus-themes-region 'bg-only)
  (modus-themes-diffs 'desaturated)
  (modus-themes-org-blocks 'grayscale)
  (modus-themes-syntax 'faint)
  :init
  (modus-themes-load-operandi))

;; If on a Mac, assume Mitsuharu Yamamoto’s fork -- check for dark/light mode,
;; if dark mode load the dark theme, also add a hook for syncing with the
;; system.
(when (eq system-type 'darwin)
  (if (string= (plist-get (mac-application-state) :appearance) "NSAppearanceNameDarkAqua")
      (modus-themes-load-vivendi))
  (add-hook 'mac-effective-appearance-change-hook 'modus-themes-toggle))

(setq-default line-spacing 1)
(setq text-scale-mode-step 1.09)

(when (eq system-type 'darwin)
  (setq facedancer-monospace "SF Mono"
        facedancer-variable  "New York"
        facedancer-monospace-size 12
        facedancer-variable-size  14)
  (facedancer-font-set)
  (set-face-attribute 'mode-line nil          :family "SF Compact Text" :height 130)
  (set-face-attribute 'mode-line-inactive nil :family "SF Compact Text" :height 130))

(when (eq system-type 'windows-nt)
  (setq facedancer-monospace "Consolas"
        facedancer-variable  "Calibri"
        facedancer-monospace-size 10
        facedancer-variable-size  11)
  (facedancer-font-set)
  (set-face-attribute 'mode-line nil          :family "Calibri" :height 110)
  (set-face-attribute 'mode-line-inactive nil :family "Calibri" :height 110))


;;; External Packages

;;;; Narrowing & Searching

(use-package orderless
  :demand
  :custom
  (completion-styles '(orderless))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles . (partial-completion))))))

(use-package vertico
  :init (vertico-mode)
  :config
  (advice-add #'vertico--setup :after
              (lambda (&rest _)
                (setq-local completion-auto-help nil
                            completion-show-inline-help nil))))

(use-package marginalia
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package embark
  :bind
  (:map embark-file-map
        ("O" . macos-open-file)
        ("j" . dired-jump))
  (:map embark-url-map
        ("d" . youtube-dl-URL-at-point)
        ("&" . browse-url-default-macosx-browser)))

(use-package consult
  :bind
  ([remap yank-pop] . consult-yank-pop)
  :custom
  (consult-preview-key (kbd "C-="))
  (consult-config
   `((consult-mark :preview-key any))))

(use-package embark-consult
  :after (embark consult)
  :demand)


;;;; Org

(use-package org
  :commands (org-mode oht-org-agenda-today)
  :config

  (custom-set-variables
   '(org-list-allow-alphabetical t)
   '(org-enforce-todo-dependencies t)
   '(org-enforce-todo-checkbox-dependencies t)
   '(org-log-done 'time)
   '(org-log-into-drawer t))

  (setq org-special-ctrl-a/e t
        org-special-ctrl-k t
        org-adapt-indentation nil
        org-catch-invisible-edits 'show-and-error
        org-outline-path-complete-in-steps nil
        org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-hide-emphasis-markers t
        org-ellipsis "..."
        org-insert-heading-respect-content t
        org-list-demote-modify-bullet '(("+" . "*") ("*" . "-") ("-" . "+"))
        org-list-indent-offset 2)

  ;; src blocks
  (setq org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0)
  (add-to-list 'org-structure-template-alist '("L" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("f" . "src fountain"))

  ;; Agenda Settings
  (setq org-agenda-window-setup 'current-window
        org-agenda-restore-windows-after-quit t
        org-agenda-start-with-log-mode t
        org-agenda-use-time-grid nil
        org-deadline-warning-days 5
        org-agenda-todo-ignore-scheduled 'all
        org-agenda-todo-ignore-deadlines 'near
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-sorting-strategy '(((agenda habit-down time-up priority-down category-up)
                                       (todo category-up priority-down)
                                       (tags priority-down category-keep)
                                       (search category-keep))))

  (setq org-agenda-files (list oht-orgfiles))

  (when (string= (system-name) "shadowfax.local")
    (add-to-list 'org-agenda-files "~/home/writing/kindred/compendium.org"))

  (setq org-agenda-custom-commands
        '(("1" "TODAY: Today's Agenda + Priority Tasks"
           ((agenda "d" ((org-agenda-span 'day)))
            (todo "TODO"
                  ((org-agenda-sorting-strategy '(todo-state-up))
                   (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))))))
          ("0" "COMPLETE: Week Agenda + All Tasks"
           ((agenda "w" ((org-agenda-span 'week)))
            (todo "TODO|LATER"
                  ((org-agenda-sorting-strategy '(todo-state-up))
                   (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled)))
                  )))))

  (setq org-todo-keywords
        '((sequence "TODO(t)" "LATER(l)" "|" "DONE(d)" "CANCELED(c)")))

  (setq org-capture-templates
        `(("p" "Personal")
          ("pi" "Personal Inbox" entry
           (file+headline ,(concat oht-orgfiles "life.org") "Inbox")
           "* %?\n\n" :empty-lines 1)
          ("pl" "Personal Log Entry" entry
           (file+olp+datetree ,(concat oht-orgfiles "logbook.org"))
           "* %?\n%T\n\n" :empty-lines 1 :tree-type month )
          ;; -----------------------------
          ("s" "Scanline")
          ("si" "Scanline Inbox" entry
           (file+headline ,(concat oht-orgfiles "scanline.org") "Inbox")
           "* %?\n\n" :empty-lines 1)
          ("sl" "Scanline Log Entry" entry
           (file+olp+datetree ,(concat oht-orgfiles "scanline_logbook.org"))
           "* %^{prompt}\n%T\n\n%?" :empty-lines 1 :tree-type week )
          ;; -----------------------------
          ("e" "Emacs Config" entry
           (file+headline ,(concat oht-orgfiles "emacs.org") "Emacs Config")
           "* TODO %?" :empty-lines 1)))

  ;; Functions for directly calling agenda commands, skipping the prompt.
  ;; Useful when paired with transient.
  (defun oht-org-agenda-today () (interactive) (org-agenda nil "1"))
  (defun oht-org-agenda-complete () (interactive) (org-agenda nil "0"))
  (defun oht-org-agenda-agenda () (interactive) (org-agenda nil "a"))
  (defun oht-org-agenda-todos () (interactive) (org-agenda nil "t"))

  ;; Functions for directly setting todo status, skipping the prompt.
  ;; Useful when paired with transient.
  (defun org-todo-set-todo () (interactive) (org-todo "TODO"))
  (defun org-agenda-todo-set-todo () (interactive) (org-agenda-todo "TODO"))
  (defun org-todo-set-later () (interactive) (org-todo "LATER"))
  (defun org-agenda-todo-set-later () (interactive) (org-agenda-todo "LATER"))
  (defun org-todo-set-done () (interactive) (org-todo "DONE"))
  (defun org-agenda-todo-set-done () (interactive) (org-agenda-todo "DONE"))
  (defun org-agenda-todo-set-canceled () (interactive) (org-agenda-todo "CANCELED"))
  (defun org-todo-set-canceled () (interactive) (org-todo "CANCELED"))

  (defun oht-org-agenda-exit-delete-window ()
    "Wrapper around org-agenda-exit & delete-window."
    (interactive)
    (org-agenda-exit)
    (delete-window))

  (defun oht-org-agenda-today-pop-up ()
    "Displays oht-org-agenda-today in a small window.
Also provides bindings for deleting the window, thus burying the
buffer, and exiting the agenda and releasing all the buffers."
    (interactive)
    (split-window-below)
    (other-window 1)
    (oht-org-agenda-today)
    (fit-window-to-buffer)
    (use-local-map (copy-keymap org-agenda-mode-map))
    (local-set-key (kbd "x") 'oht-org-agenda-exit-delete-window)
    (local-set-key (kbd "q") 'delete-window))

  (transient-define-prefix oht-transient-org ()
    "Transient for Org Mode"
    ["Org Mode"
     ["Navigation"
      ("o" "Outline" consult-outline)
      ("n" "Narrow/Widen" narrow-or-widen-dwim)
      ("g" "Go To" org-goto)
      ("m" "Visible Markup" visible-mode)]
     ["Item"
      ("t" "TODO" oht-transient-org-todo)
      ("I" "Clock In" org-clock-in)
      ("O" "Clock Out" org-clock-out)
      ("a" "Archive Subtree" org-archive-subtree)
      ("r" "Refile" org-refile)
      ("c" "Checkbox" org-toggle-checkbox)]
     ["Insert"
      ("." "Insert Date, Active" org-insert-date-today)
      (">" "Insert Date, Inactive" org-insert-date-today-inactive)
      ("<" "Structure Template" org-insert-structure-template)]
     ["Links"
      ("s" "Store Link" org-store-link)
      ("i" "Insert Link" org-insert-last-stored-link)]])

  (transient-define-prefix oht-transient-org-todo ()
    "A transient for setting org todo status.
I've created this because I don't like how org-todo messes with
windows. There is likely a much better way to automatically map
org-todo-keywords to a transient command."
    ["Org mode -> Change Status To..."
     [("t" "TODO"     org-todo-set-todo)
      ("l" "LATER"    org-todo-set-later)]
     [("d" "DONE"     org-todo-set-done)
      ("c" "CANCELED" org-todo-set-canceled)]])

  ) ; End "use-package org"


(use-package org-agenda
  :commands org-agenda
  :bind
  (:map org-agenda-mode-map
        ("t" . oht-transient-org-agenda)
        ("C-/" . org-agenda-undo))
  :hook (org-agenda-mode-hook . hl-line-mode)
  :config
  (transient-define-prefix oht-transient-org-agenda ()
    "A transient for setting org-agenda todo status.
I've created this because I don't like how org-todo messes with
windows. There is likely a much better way to automatically map
org-todo-keywords to a transient command."
    ["Change Status To..."
     [("t" "TODO"     org-agenda-todo-set-todo)
      ("l" "LATER"    org-agenda-todo-set-later)]
     [("d" "DONE"     org-agenda-todo-set-done)
      ("c" "CANCELED" org-agenda-todo-set-canceled)]]))


;;;; View / Selected

(defun define-navigation-keys (map)
  "Defines navigation keys for a map supplied by argument."
  (interactive "S")
  (define-key map (kbd "n") 'next-line)
  (define-key map (kbd "p") 'previous-line)
  (define-key map (kbd "f") 'forward-char)
  (define-key map (kbd "b") 'backward-char)
  (define-key map (kbd "F") 'forward-word)
  (define-key map (kbd "B") 'backward-word)
  (define-key map (kbd "a") 'beginning-of-line)
  (define-key map (kbd "e") 'end-of-line)
  (define-key map (kbd "{") 'backward-paragraph)
  (define-key map (kbd "}") 'forward-paragraph)
  (define-key map (kbd "(") 'backward-sentence)
  (define-key map (kbd ")") 'forward-sentence)
  (define-key map (kbd "s") 'isearch-forward)
  (define-key map (kbd "r") 'isearch-backward)
  (define-key map (kbd "[") 'scroll-down-line)
  (define-key map (kbd "]") 'scroll-up-line)
  (define-key map (kbd "x") 'exchange-point-and-mark)
  (define-key map (kbd "M") 'rectangle-mark-mode))

(use-package view
  :custom
  (view-read-only t)
  :init
  (defun oht/view-mode-exit ()
    (interactive)
    (view-mode -1)
    (hl-line-mode -1))
  (defun oht/exit-view-replace-rectangle ()
    (interactive)
    (oht/view-mode-exit)
    (call-interactively 'replace-rectangle))
  :bind
  (:map view-mode-map
        ("R" . oht/exit-view-replace-rectangle)
        ("m" . set-mark-command)
        ("<RET>" . oht/view-mode-exit)
        ("q" . quit-window))
  :hook (view-mode-hook . hl-line-mode)
  :config
  (define-navigation-keys view-mode-map)
  :blackout " VIEW")

(use-package selected
  :commands selected-minor-mode
  :init
  (selected-global-mode 1)
  (defun disable-selected-minor-mode ()
    (selected-minor-mode -1))
  :bind (:map selected-keymap
              ("u" . upcase-dwim)
              ("d" . downcase-dwim)
              ("w" . kill-ring-save)
              ("l" . mark-whole-line)
              ("|" . pipe-region)
              ("R" . replace-rectangle)
              ("E" . eval-region)
              ("q" . selected-off))
  :config
  (define-navigation-keys selected-keymap)
  :blackout selected-minor-mode)


;;;; Browser & News

(setq shr-max-image-proportion 0.5)
(setq shr-width 80)
(setq shr-bullet "• ")

;; Set default browser in Emacs
(setq browse-url-browser-function 'eww-browse-url)
;; Prefixing with universal argument uses browse-url-default-browser
;; which seems to be the system browser.

(use-package eww
  :custom
  (eww-restore-desktop nil)
  (eww-desktop-remove-duplicates t)
  (eww-header-line-format "%t %u")
  (eww-download-directory user-downloads-directory)
  (eww-bookmarks-directory (concat user-emacs-directory "eww-bookmarks/"))
  (eww-history-limit 150)
  (eww-use-external-browser-for-content-type "\\`\\(video/\\|audio/\\|application/pdf\\)")
  (url-cookie-trusted-urls '()
                           url-cookie-untrusted-urls '(".*"))
  :init
  (defun oht-eww-fonts ()
    "Apply some customization to fonts in eww-mode."
    (facedancer-vadjust-mode)
    (text-scale-increase 1)
    (setq-local line-spacing 2))
  :commands (eww)
  :hook (eww-mode-hook . oht-eww-fonts)
  :config

  (make-variable-buffer-local
   (defvar eww-inhibit-images-status nil
     "EWW Inhibit Images Status"))

  (defun eww-inhibit-images-toggle ()
    (interactive)
    (setq eww-inhibit-images-status (not eww-inhibit-images-status))
    (if eww-inhibit-images-status
        (progn (setq-local shr-inhibit-images t)
               (eww-reload t))
      (progn (setq-local shr-inhibit-images nil)
             (eww-reload t))))

  (defun oht-eww-open-in-new-buffer-bury ()
    "Open URL at point in a new buried buffer"
    (interactive)
    (eww-open-in-new-buffer)
    (quit-window)
    (message "Browsing in buried buffer"))

  (defun prot-eww--rename-buffer ()
    "Rename EWW buffer using page title or URL.
To be used by `eww-after-render-hook'."
    (let ((name (if (eq "" (plist-get eww-data :title))
                    (plist-get eww-data :url)
                  (plist-get eww-data :title))))
      (rename-buffer (format "*eww # %s*" name) t)))

  (add-hook 'eww-after-render-hook #'prot-eww--rename-buffer)
  (advice-add 'eww-back-url :after #'prot-eww--rename-buffer)
  (advice-add 'eww-forward-url :after #'prot-eww--rename-buffer)

  ) ; End "use-package eww"

(use-package elfeed
  :if (string= (system-name) "shadowfax.local")
  :commands elfeed
  :custom
  (elfeed-use-curl t)
  (elfeed-curl-max-connections 10)
  (elfeed-db-directory (concat user-emacs-directory "elfeed/"))
  (elfeed-enclosure-default-dir user-downloads-directory)
  (elfeed-search-filter "@4-week-ago +unread")
  (elfeed-sort-order 'descending)
  (elfeed-search-clipboard-type 'CLIPBOARD)
  (elfeed-show-truncate-long-urls t)
  :bind
  (:map elfeed-search-mode-map
        ("b" . elfeed-search-browse-url)
        ("B" . oht-elfeed-search-browse-and-bury)
        ("*" . elfeed-search-tag--star)
        ("8" . elfeed-search-untag--star)
        ("o" . delete-other-windows)
        ("N" . oht-elfeed-unread-news)
        ("E" . oht-elfeed-unread-emacs)
        ("O" . oht-elfeed-unread-other)
        ("S" . oht-elfeed-starred))
  (:map elfeed-show-mode-map
        ("&" . oht-elfeed-show-visit-generic)
        ("r" . elfeed-show-tag--read)
        ("u" . elfeed-show-tag--unread)
        ("*" . elfeed-show-tag--star)
        ("8" . elfeed-show-tag--unstar)
        ("o" . delete-other-windows)
        ("d" . oht-elfeed-show-download-video)
        ("i" . elfeed-inhibit-images-toggle)
        ("B" . oht-elfeed-show-browse-and-bury))
  :config
  ;; My feed list is stored outside my dotfiles -- not public.
  (load "~/home/src/rss-feeds.el")

  (defun oht-elfeed-show-fonts ()
    "Apply some customization to fonts in elfeed-show-mode."
    (facedancer-vadjust-mode)
    (setq-local line-spacing 3))

  ;; Elfeed doesn't have a built-in way of flagging or marking items for later,
  ;; but it does have tags, which you can use for this. The below is some simple
  ;; aliases for adding and removing the 'star' tag.
  (defalias 'elfeed-search-tag--star
    (elfeed-expose #'elfeed-search-tag-all 'star)
    "Add the 'star' tag to all selected entries")
  (defalias 'elfeed-search-untag--star
    (elfeed-expose #'elfeed-search-untag-all 'star)
    "Remove the 'star' tag to all selected entries")
  (defalias 'elfeed-show-tag--star
    (elfeed-expose #'elfeed-show-tag 'star)
    "Add the 'star' tag to current entry")
  (defalias 'elfeed-show-tag--unstar
    (elfeed-expose #'elfeed-show-untag 'star)
    "Remove the 'star' tag to current entry")

  ;; Even though there are bindings for marking items as 'read' and 'unread' in
  ;; the search-mode, there are no such built-in bindings for show-mode. So we
  ;; add them here.
  (defalias 'elfeed-show-tag--unread
    (elfeed-expose #'elfeed-show-tag 'unread)
    "Mark the current entry unread.")
  (defalias 'elfeed-show-tag--read
    (elfeed-expose #'elfeed-show-untag 'unread)
    "Mark the current entry read.")

  (defun oht-elfeed-unread-news  () (interactive) (elfeed-search-set-filter "+unread +news"))
  (defun oht-elfeed-unread-emacs () (interactive) (elfeed-search-set-filter "+unread +emacs"))
  (defun oht-elfeed-unread-other () (interactive) (elfeed-search-set-filter "+unread -emacs -news"))
  (defun oht-elfeed-starred      () (interactive) (elfeed-search-set-filter "+star"))

  (defun oht-elfeed-show-visit-generic ()
    "Wrapper for elfeed-show-visit to use system browser instead of eww"
    (interactive)
    (let ((browse-url-generic-program "/usr/bin/open"))
      (elfeed-show-visit t)))

  (make-variable-buffer-local
   (defvar elfeed-inhibit-images-status nil
     "Elfeed Inhibit Images Status"))

  (defun elfeed-inhibit-images-toggle ()
    "Toggle display of images in elfeed-show."
    (interactive)
    (setq elfeed-inhibit-images-status (not elfeed-inhibit-images-status))
    (if elfeed-inhibit-images-status
        (progn
          (setq-local shr-inhibit-images t)
          (elfeed-show-refresh))
      (progn
        (setq-local shr-inhibit-images nil)
        (elfeed-show-refresh))))

  (defun oht-elfeed-show-download-video ()
    "In elfeed-show-mode, download a video using youtube-dl."
    (interactive)
    (async-shell-command (format "%s -o \"%s%s\" -f mp4 \"%s\""
                                 youtube-dl-path
                                 youtube-dl-output-dir
                                 "%(title)s.%(ext)s"
                                 (elfeed-entry-link elfeed-show-entry))))

  (defun oht-elfeed-search-browse-and-bury ()
    "Browse elfeed entry and bury buffer."
    (interactive)
    (elfeed-search-browse-url)
    (bury-buffer)
    (message "Browsing in buried buffer"))

  (defun oht-elfeed-show-browse-and-bury ()
    "Browse elfeed entry and bury buffer."
    (interactive)
    (elfeed-show-visit)
    (bury-buffer)
    (message "Browsing in buried buffer"))

  :hook ((elfeed-show-mode-hook . oht-elfeed-show-fonts)
         (elfeed-search-mode-hook . disable-selected-minor-mode)
         (elfeed-show-mode-hook . disable-selected-minor-mode))

  ) ; End "use-package elfeed"


;;;; Transient

(use-package transient
  :init
  (autoload 'org-store-link "org")
  (autoload 'dired-jump "dired" nil t)
  :config

  (transient-define-prefix oht-transient-general ()
    "General-purpose transient."
    [["Actions/Toggles"
      ("a" "AutoFill" auto-fill-mode)
      ("j" "Dired Jump" dired-jump)
      ("v" "View Mode" view-mode)
      ("b" "Switch Buffer" consult-buffer)
      ("B" "iBuffer" ibuffer)
      ("m" "Mode Transient..." call-mode-help-transient)]
     ["Reading"
      ("r e" "Elfeed"      elfeed)
      ("r E" "EWW"         eww)
      ("r g" "Google News" oht-dispatch-google-news)
      ("r d" "Downloads"   oht-dispatch-downloads)]
     ["Transients"
      ("o" "Org..." oht-transient-general--org)
      ("t" "Toggle..." oht-transient-general--toggles)
      ("w" "Windows..." oht-transient-window)
      ("c" "Consult..." oht-transient-general--consult)]
     [""
      ("0" "Outline..." oht-transient-outline)
      ("2" "Secondary..." oht-transient-2nd)
      ("f" "Fonts..." oht-transient-fonts)
      ("s" "Spelling..." flyspell-mode-transient)]])

  (transient-define-prefix oht-transient-general--org ()
    "Transient for Org commands useful outside org mode."
    ["Org Mode"
     ["Agenda Commands"
      ("t" "Today" oht-org-agenda-today)
      ("p" "Today (pop-up)" oht-org-agenda-today-pop-up)
      ("0" "Complete" oht-org-agenda-complete)
      ("a" "Agenda..." org-agenda)]
     ["Other"
      ("k" "Capture" org-capture)
      ("s" "Store Link" org-store-link)]])

  (transient-define-prefix oht-transient-general--toggles ()
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Toggle"
     ("h" "Highlight Line" hl-line-mode)
     ("l" "Line Numbers" global-display-line-numbers-mode)
     ("g" "Fill Column" global-display-fill-column-indicator-mode)
     ("w" "Wrap" visual-line-mode)
     ("t" "Truncate" toggle-truncate-lines)
     ("W" "Whitespace" whitespace-mode)]
     ["Action"
      ("q" "Quit" transient-quit-all)]])

  (transient-define-prefix oht-transient-general--consult ()
    ["Consult"
     ("l" "Line" consult-line)
     ("o" "Outline" consult-outline)
     ("g" "Grep" consult-grep)
     ("b" "Buffer" consult-buffer)
     ("a" "Apropos" consult-apropos)
     ("m" "Marks" consult-mark)
     ("M" "Minor Modes" consult-minor-mode-menu)])

  (transient-define-prefix oht-transient-outline ()
    "Transient for Outline Minor Mode navigation"
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Show/Hide"
      ("<backtab>" "Global Toggle" bicycle-cycle-global)
      ("<tab>" "Toggle Children" bicycle-cycle)
      ("o"     "Hide to This Sublevel" outline-hide-sublevels)
      ("a"     "Show All" outline-show-all)]
     ["Navigate"
      ("n" "Next" outline-next-visible-heading)
      ("p" "Previous" outline-previous-visible-heading)]
     ["Edit"
      ("M-<left>"  "Promote" outline-promote)
      ("M-<right>" "Demote"  outline-demote)
      ("M-<up>"    "Move Up" outline-move-subtree-up)
      ("M-<down>"  "Move Down" outline-move-subtree-down)]
     ["Other"
      ("C-/" "Undo" undo-fu-only-undo)
      ("M-/" "Redo" undo-fu-only-redo)
      ("c" "Consult" consult-outline :transient nil)]])

  (transient-define-prefix oht-transient-fonts ()
    "Set Font Properties"
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Modes"
      ("v" "Var Mode" variable-pitch-mode)
      ("V" "V+ Mode" facedancer-vadjust-mode)
      ("o" "Olivetti" olivetti-mode)
      ("w" "Wrap" visual-line-mode)]
     ["Size"
      ("0" "Reset Size" text-scale-mode)
      ("=" "Larger" text-scale-increase)
      ("+" "Larger" text-scale-increase)
      ("-" "Smaller" text-scale-decrease)]
     ["Other"
      ("s" "Line Spacing" facedancer-line-spacing)
      ("m" "Modus Toggle" modus-themes-toggle)]])

  (transient-define-prefix oht-transient-window ()
    "Most commonly used window commands"
    [["Splits"
      ("s" "Horizontal" split-window-below)
      ("v" "Vertical"   split-window-right)
      ("b" "Balance"    balance-windows)
      ("f" "Fit"        fit-window-to-buffer)
      ("r" "Rotate"     toggle-window-split)
      ("F" "Find Other Win" find-file-other-window)]
     ["Window"
      ("c" "Clone Indirect" clone-indirect-buffer)
      ("t" "Tear Off" tear-off-window)
      ("k" "Kill" delete-window)
      ("K" "Kill Buffer+Win"  kill-buffer-and-window)
      ("o" "Kill Others"  delete-other-windows)
      ("m" "Maximize" maximize-window)]
     ["Navigate"
      ("<left>"  "←" windmove-left  :transient t)
      ("<right>" "→" windmove-right :transient t)
      ("<up>"    "↑" windmove-up    :transient t)
      ("<down>"  "↓" windmove-down  :transient t)]
     ["Move"
      ("S-<left>"  "Move ←" buf-move-left  :transient t)
      ("S-<right>" "Move →" buf-move-right :transient t)
      ("S-<up>"    "Move ↑" buf-move-up    :transient t)
      ("S-<down>"  "Move ↓" buf-move-down  :transient t)]
     ["Undo/Redo"
      ("C-/" "Winner Undo" winner-undo :transient t)
      ("M-/" "Winner Redo" winner-redo :transient t)]
     ["Exit"
      ("q" "Quit" transient-quit-all)]])

  ) ; End "use-package transient"

;;;; Mode Help Transients

;; Emacs has so many modes. Who can remember all the commands? These
;; mode-specific transients are designed to help with that.

(defun call-mode-help-transient ()
  "Call a helpful transient based on the mode you're in."
  (interactive)
  (if (progn
        (when (derived-mode-p 'Info-mode)
          (info-mode-help-transient))
        (when (derived-mode-p 'dired-mode)
          (dired-mode-help-transient))
        (when (derived-mode-p 'eww-mode)
          (eww-mode-help-transient)))
      nil ; if the above succeeds, do nothing, else...
    (message "No transient defined for this mode.")))

(with-eval-after-load 'info
  (transient-define-prefix info-mode-help-transient ()
    "Transient for Info mode"
    ["Info"
     [("d" "Info Directory" Info-directory)
      ("m" "Menu" Info-menu)
      ("F" "Go to Node" Info-goto-emacs-command-node)]
     [("s" "Search regex Info File" Info-search)
      ("i" "Index" Info-index)
      ("I" "Index, Virtual" Info-virtual-index)]]
    ["Navigation"
     [("l" "Left, History" Info-history-back)
      ("r" "Right, History" Info-history-forward)
      ("L" "List, History" Info-history)]
     [("T" "Table of Contents" Info-toc)
      ("n" "Next Node" Info-next)
      ("p" "Previous Node" Info-prev)
      ("u" "Up" Info-up)]
     [("<" "Top Node" Info-top-node)
      (">" "Final Node" Info-final-node)
      ("[" "Forward Node" Info-backward-node)
      ("]" "Backward Node" Info-forward-node)]]))

(with-eval-after-load 'dired
  (transient-define-prefix dired-mode-help-transient ()
    "Transient for dired commands"
    ["Dired Mode"
     ["Action"
      ("RET" "Open file"            dired-find-file)
      ("o" "  Open in other window" dired-find-file-other-window)
      ("C-o" "Open in other window (No select)" dired-display-file)
      ("v" "  Open file (View mode)"dired-view-file)
      ("=" "  Diff"                 dired-diff)
      ("w" "  Copy filename"        dired-copy-filename-as-kill)
      ("W" "  Open in browser"      browse-url-of-dired-file)
      ("y" "  Show file type"       dired-show-file-type)]
     ["Attribute"
      ("R"   "Rename"               dired-do-rename)
      ("G"   "Group"                dired-do-chgrp)
      ("M"   "Mode"                 dired-do-chmod)
      ("O"   "Owner"                dired-do-chown)
      ("T"   "Timestamp"            dired-do-touch)]
     ["Navigation"
      ("j" "  Goto file"            dired-goto-file)
      ("+" "  Create directory"     dired-create-directory)
      ("<" "  Jump prev directory"  dired-prev-dirline)
      (">" "  Jump next directory"  dired-next-dirline)
      ("^" "  Move up directory"    dired-up-directory)]
     ["Display"
      ("g" "  Refresh buffer"       revert-buffer)
      ("l" "  Refresh file"         dired-do-redisplay)
      ("k" "  Remove line"          dired-do-kill-lines)
      ("s" "  Sort"                 dired-sort-toggle-or-edit)
      ("(" "  Toggle detail info"   dired-hide-details-mode)
      ("i" "  Insert subdir"        dired-maybe-insert-subdir)
      ("$" "  Hide subdir"          dired-hide-subdir)
      ("M-$" "Hide subdir all"      dired-hide-subdir)]
     ["Extension"
      ("e"   "wdired"               wdired-change-to-wdired-mode)
      ("/"   "dired-filter"         ignore)
      ("n"   "dired-narrow"         ignore)]]
    [["Marks"
      ("m" "Marks..." dired-mode-help-transient--marks)]])
  (transient-define-prefix dired-mode-help-transient--marks ()
    "Sub-transient for dired marks"
    ["Dired Mode -> Marks"
     ["Toggles"
      ("mm"  "Mark"                 dired-mark)
      ("mM"  "Mark all"             dired-mark-subdir-files)
      ("mu"  "Unmark"               dired-unmark)
      ("mU"  "Unmark all"           dired-unmark-all-marks)
      ("mc"  "Change mark"          dired-change-marks)
      ("mt"  "Toggle mark"          dired-toggle-marks)]
     ["Type"
      ("m*"  "Executables"          dired-mark-executables)
      ("m/"  "Directories"          dired-mark-directories)
      ("m@"  "Symlinks"             dired-mark-symlinks)
      ("m&"  "Garbage files"        dired-flag-garbage-files)
      ("m#"  "Auto save files"      dired-flag-auto-save-files)
      ("m~"  "backup files"         dired-flag-backup-files)
      ("m."  "Numerical backups"    dired-clean-directory)]
     ["Search"
      ("m%"  "Regexp"               dired-mark-files-regexp)
      ("mg"  "Regexp file contents" dired-mark-files-containing-regexp)]]
    [["Act on Marked"
      ("x"   "Do action"            dired-do-flagged-delete)
      ("C"   "Copy"                 dired-do-copy)
      ("D"   "Delete"               dired-do-delete)
      ("S"   "Symlink"              dired-do-symlink)
      ("H"   "Hardlink"             dired-do-hardlink)
      ("P"   "Print"                dired-do-print)
      ("A"   "Find"                 dired-do-find-regexp)
      ("Q"   "Replace"              dired-do-find-regexp-and-replace)
      ("B"   "Elisp bytecompile"    dired-do-byte-compile)
      ("L"   "Elisp load"           dired-do-load)
      ("X"   "Shell command"        dired-do-shell-command)
      ("Z"   "Compress"             dired-do-compress)
      ("z"   "Compress to"          dired-do-compress-to)
      ("!"   "Shell command"        dired-do-shell-command)
      ("&"   "Async shell command"  dired-do-async-shell-command)]])
  ) ; End dired config

(with-eval-after-load 'eww
  (transient-define-prefix eww-mode-help-transient ()
    "Transient for EWW"
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    ["EWW"
     ["Actions"
      ("G" "Browse" eww)
      ("M-<return>" "Open in new buffer" oht-eww-open-in-new-buffer-bury)
      ("&" "Browse With External Browser" eww-browse-with-external-browser)
      ("w" "Copy URL" eww-copy-page-url)]
     ["Display"
      ("i" "Toggle Images" eww-inhibit-images-toggle)
      ("F" "Toggle Fonts" eww-toggle-fonts)
      ("R" "Readable" eww-readable)
      ("M-C" "Colors" eww-toggle-colors)]
     ["History"
      ("H" "History" eww-list-histories)
      ("l" "Back" eww-back-url)
      ("r" "Forward" eww-forward-url)]
     ["Bookmarks"
      ("a" "Add Eww Bookmark" eww-add-bookmark)
      ("b" "Bookmark" bookmark-set)
      ("B" "List Bookmarks" eww-list-bookmarks)
      ("M-n" "Next Bookmark" eww-next-bookmark)
      ("M-p" "Previous Bookmark" eww-previous-bookmark)]]))


;;;; Misc Packages

(use-package magit
  :if (when (eq system-type 'darwin))
  :commands magit-status)

(use-package olivetti
  :commands olivetti-mode
  :custom (olivetti-body-width 84)
  :blackout " Olvti")

(use-package undo-fu
  :bind
  ("C-/" . undo-fu-only-undo)
  ("M-/" . undo-fu-only-redo))

(use-package unfill
  :commands (unfill-paragraph unfill-toggle unfill-region)
  :bind
  ("M-q" . unfill-toggle))

(use-package helpful
  :bind
  ("C-h f" . #'helpful-function)
  ("C-h v" . #'helpful-variable)
  ("C-h o" . #'helpful-symbol)
  ("C-h k" . #'helpful-key)
  ("C-h p" . #'helpful-at-point))

(use-package move-text
  :commands (move-text-up move-text-down)
  :bind
  ("C-x C-t" . oht-transient-transpose-lines)
  :config
  (transient-define-prefix oht-transient-transpose-lines ()
    :transient-suffix 'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Move Lines"
      ("n" "Down" move-text-down)
      ("p" "Up" move-text-up)]]))

(use-package buffer-move
  :commands (buf-move-up
             buf-move-down
             buf-move-left
             buf-move-right))

(use-package visual-regexp
  :bind (([remap query-replace] . #'vr/query-replace)))

(use-package visual-regexp-steroids
  :after visual-regexp
  :bind (([remap query-replace-regexp] . #'vr/query-replace))
  :custom
  (vr/engine 'pcre2el))

(use-package bicycle
  :after outline
  :bind
  (:map outline-minor-mode-map
        ([C-tab] . bicycle-cycle))
  (:map emacs-lisp-mode-map
        ("<backtab>" . bicycle-cycle-global)))

(use-package fountain-mode
  :commands fountain-mode
  :custom
  (fountain-add-continued-dialog nil)
  (fountain-highlight-elements (quote (section-heading))))

(use-package markdown-mode
  :mode ("\\.text" . markdown-mode)
  :magic ("%text" . markdown-mode)
  :commands markdown-mode)

(use-package lua-mode
  :commands lua-mode)

(use-package oblique
  :if (string= (system-name) "shadowfax.local")
  :load-path "~/home/src/oblique-strategies/"
  :commands (oblique-strategy)
  :init
  (setq initial-scratch-message (concat
                                 ";; Welcome to Emacs!\n;; This is the scratch buffer, for unsaved text and Lisp evaluation.\n"
                                 ";; Oblique Strategy: " (oblique-strategy) "\n\n")))


;;; End of init.el
