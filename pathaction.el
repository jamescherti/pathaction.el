;;; pathaction.el --- Execute the pathaction.yaml rules from your editor -*- lexical-binding: t; -*-

;; Copyright (C) 2025-2026 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti <https://www.jamescherti.com/contact/>
;; Version: 1.0.1
;; URL: https://github.com/jamescherti/pathaction.el
;; Keywords: convenience
;; Package-Requires: ((emacs "25.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; The pathaction Emacs package provides an interface for executing
;; `.pathaction.yaml' rules directly from Emacs through the `pathaction'
;; command-line tool.
;;
;; The pathaction command-line tool evaluates a target file or directory against
;; a declarative rule set defined in `.pathaction.yaml' and runs the associated
;; command automatically. By passing a path as an argument, actions are resolved
;; and executed according to matching rules.
;;
;; The rule set is written in YAML and supports Jinja2 templating, enabling
;; dynamic command construction based on the target path. This separates
;; configuration from execution logic and offers a flexible framework for
;; automating file and directory operations.
;;
;; Links:
;; ------
;; - The pathaction.el Emacs package:
;;   https://github.com/jamescherti/pathaction.el/
;;
;; - Pathaction cli:
;;   https://github.com/jamescherti/pathaction

;;; Code:

(require 'seq)

(defgroup pathaction nil
  "Execute pathaction.yaml rules using pathaction."
  :group 'pathaction
  :prefix "pathaction-"
  :link '(url-link
          :tag "Github"
          "https://github.com/jamescherti/pathaction.el"))

(defcustom pathaction-close-window-after-execution t
  "Determines whether the pathaction window is closed after execution.
If non-nil, the pathaction window will be closed once execution is complete.

If the pathaction operation is performed in the same window, it switches
back to the previously displayed buffer instead of closing it."
  :type 'boolean
  :group 'pathaction)

(defcustom pathaction-keep-buffer-when-process-running t
  "If non-nil, keep hidden pathaction buffers if they have an active process."
  :type 'boolean
  :group 'pathaction)

(defun pathaction--default-ansi-term (command name)
  "Default function to run COMMAND in `ansi-term' named NAME."
  (let ((term-buffer (ansi-term shell-file-name name)))
    (process-send-string (get-buffer-process term-buffer)
                         (concat command "; exit\n"))
    term-buffer))

(defvar pathaction-term-function #'pathaction--default-ansi-term
  "The function used to create and execute the terminal.
Defaults to `pathaction--default-ansi-term'.

- This function should return the terminal buffer.
- This function takes the command to execute as the first argument and the name
  of the buffer as the second argument.
  Example: (function-name command buffername)")

;; Silence warnings
(defvar term-suppress-hard-newline)

(defun pathaction-save-buffer ()
  "Save the current buffer if it is visiting a file."
  (let ((file-name (buffer-file-name (buffer-base-buffer)))
        (inhibit-message t))
    (when file-name
      (save-buffer))))

(defcustom pathaction-before-run-hook '(pathaction-save-buffer)
  "Hooks to run before `pathaction-run' executes the `pathaction' command."
  :group 'pathaction
  :type 'hook)

(defcustom pathaction-after-create-buffer-hook nil
  "Hooks to run after the pathaction buffer is created.
This hook is executed from the pathaction buffer, allowing further
customization or actions once the buffer is ready."
  :group 'pathaction
  :type 'hook)

;; Internal variables
(defvar-local pathaction--enabled nil)

(defvar pathaction--active-buffers nil
  "List of active pathaction buffers.")

(defun pathaction--message (&rest args)
  "Display a message with '[pathaction]' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] " (car args)) (cdr args)))

(defun pathaction--warning (&rest args)
  "Display a warning message with '[pathaction] Warning: ' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] Warning: " (car args)) (cdr args)))

(defun pathaction--kill-hidden-pathaction-buffers ()
  "Kill pathaction buffers that are no longer displayed in any window."
  (let ((window-configuration-change-hook nil) ; Prevents an infinite loop
        (kept-buffers nil))
    (dolist (buf pathaction--active-buffers)
      (when (buffer-live-p buf)
        (let* ((process (get-buffer-process buf))
               (has-active-process (and process (process-live-p process)))
               (is-visible (or (get-buffer-window buf 'visible)
                               (and (bound-and-true-p tab-bar-mode)
                                    (fboundp 'tab-bar-get-buffer-tab)
                                    (funcall 'tab-bar-get-buffer-tab buf t nil)))))
          (if (or is-visible
                  (and pathaction-keep-buffer-when-process-running
                       has-active-process))
              (push buf kept-buffers)
            (when process
              (set-process-query-on-exit-flag process nil))
            (kill-buffer buf)))))
    (setq pathaction--active-buffers kept-buffers)
    (unless pathaction--active-buffers
      (remove-hook 'window-configuration-change-hook
                   #'pathaction--kill-hidden-pathaction-buffers))))

(defun pathaction-quit (buffer)
  "Quit pathaction running in BUFFER."
  (when (buffer-live-p buffer)
    (when (buffer-local-value 'pathaction--enabled buffer)
      (let ((win (get-buffer-window buffer 'visible)))
        (when (and (window-live-p win)
                   pathaction-close-window-after-execution
                   (not (one-window-p t)))
          (delete-window win)))
      (kill-buffer buffer)))
  (setq pathaction--active-buffers
        (seq-filter #'buffer-live-p pathaction--active-buffers))
  (unless pathaction--active-buffers
    (remove-hook 'window-configuration-change-hook
                 #'pathaction--kill-hidden-pathaction-buffers)))

(defun pathaction--run-using-terminal (command name term-function)
  "Run COMMAND using the terminal opened by `pathaction-term-function'.
NAME is the buffer name (prefix and suffix it with \\='*\\=')
TERM-FUNCTION is the function that executes a terminal."
  (let* ((term-buffer-process nil)
         (term-buffer (funcall term-function command name)))
    (unless (buffer-live-p term-buffer)
      (error "The buffer %s returned by the %s function could not be found"
             term-buffer term-function))

    (setq term-buffer-process (get-buffer-process term-buffer))

    (when term-buffer-process
      (with-current-buffer term-buffer
        (run-hooks 'pathaction-after-create-buffer-hook)
        (setq-local mode-line-format nil)
        (setq-local scroll-margin 0)
        (setq-local scroll-conservatively 0)
        (setq-local term-suppress-hard-newline t)
        (setq-local show-trailing-whitespace nil)
        (setq-local display-line-numbers nil)
        (setq pathaction--enabled t))

      (push term-buffer pathaction--active-buffers)

      (set-process-sentinel term-buffer-process
                            (lambda (process _event)
                              (when (and (buffer-live-p term-buffer)
                                         (memq (process-status process)
                                               '(exit signal)))
                                (pathaction-quit (process-buffer process))))))))

(defun pathaction--buffer-path ()
  "Return the full path of the current buffer.
If the buffer is a non-file visiting buffer (e.g., `dired'), returns the
`default-directory' path.
If the buffer is visiting a file, returns the full path to the file."
  (let ((file-name (buffer-file-name (buffer-base-buffer))))
    (if file-name
        ;; Return the file name
        file-name
      default-directory)))

;;;###autoload
(defun pathaction-edit ()
  "Edit the pathaction.yaml file."
  (interactive)

  (unless (executable-find "pathaction")
    (user-error "'pathaction' command not found in $PATH"))

  (let* ((file-list (shell-command-to-string "pathaction -l ."))
         (file-list-lines (split-string file-list "\n" t))
         (existing-files (seq-filter (lambda (file)
                                       (and (not (string-empty-p file))
                                            (file-exists-p file)))
                                     file-list-lines)))

    (unless existing-files
      (error "No existing files available to edit"))

    (find-file (completing-read "Select a file: " existing-files))))

;;;###autoload
(defun pathaction-run (tag)
  "Execute a pathaction action identified by TAG.
Prompts the user for a TAG and executes the corresponding pathaction command.
If invoked in a file buffer, uses the file's directory as the target.
If invoked in a Dired buffer, uses the Dired directory.
The command opens a terminal buffer named based on the TAG and the file or
directory being processed."
  (interactive "sTag: ")
  (let ((file-name (pathaction--buffer-path)))
    (unless (executable-find "pathaction")
      (user-error "'pathaction' command not found in $PATH"))

    (run-hooks 'pathaction-before-run-hook)

    (let* ((switch-to-buffer-obey-display-actions t)
           (directory (file-name-directory file-name))
           (base-name (file-name-nondirectory (directory-file-name file-name)))
           (command (when directory
                      (format "pathaction --confirm-after --tag %s %s"
                              (shell-quote-argument tag)
                              (shell-quote-argument file-name)))))
      (ignore switch-to-buffer-obey-display-actions)
      (when command
        (add-hook 'window-configuration-change-hook
                  #'pathaction--kill-hidden-pathaction-buffers)
        (pathaction--run-using-terminal
         command
         (format "pathaction:%s-%s" tag base-name)
         pathaction-term-function)))))

(provide 'pathaction)

;;; pathaction.el ends here
