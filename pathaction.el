;;; pathaction.el --- Execute the pathaction.yaml rules from your editor -*- lexical-binding: t; -*-

;; Copyright (C) 2025 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 0.9.9
;; URL: https://github.com/jamescherti/pathaction.el
;; Keywords: convenience
;; Package-Requires: ((emacs "24.4"))
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
;; Execute pathaction.yaml rules using pathaction

;;; Code:

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

(defvar pathaction-after-create-buffer-hook nil
  "Hooks to run after the pathaction buffer is created.
This hook is executed from the pathaction buffer, allowing further
customization or actions once the buffer is ready.")

;; Internal variables
(defvar-local pathaction--enabled nil)

(defun pathaction--message (&rest args)
  "Display a message with '[pathaction]' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] " (car args)) (cdr args)))

(defun pathaction--warning (&rest args)
  "Display a warning message with '[pathaction] Warning: ' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] Warning: " (car args)) (cdr args)))

(defun pathaction-quit (&optional buffer)
  "Quit pathaction running in BUFFER.
If BUFFER is not provided, uses the current buffer."
  (when pathaction--enabled
    (unless buffer
      (setq buffer (current-buffer)))

    (when (and pathaction-close-window-after-execution
               (> (length (window-list)) 1))
      (delete-window))

    (kill-buffer buffer)))

(defun pathaction--ansi-term (command name)
  "Run COMMAND using \\='ansi-term\\='.
NAME is the buffer name (ansi-term prefix and suffix it with \\='*\\=')"
  (let* ((term-buffer-process nil)
         (term-buffer-name (ansi-term command name))
         (term-buffer (get-buffer term-buffer-name)))
    (when term-buffer
      (setq term-buffer-process (get-buffer-process term-buffer)))

    (when term-buffer-process
      (when pathaction-after-create-buffer-hook
        (with-current-buffer term-buffer
          (run-hooks 'pathaction-after-create-buffer-hook)))

      (with-current-buffer term-buffer
        (setq pathaction--enabled t))

      (set-process-sentinel term-buffer-process
                            (lambda (_process event)
                              (when (string-prefix-p "finished" event)
                                (with-current-buffer term-buffer
                                  (pathaction-quit))))))))

(defun pathaction--buffer-path ()
  "Return the full path of the current buffer.
If the buffer is in `dired-mode', returns the directory path.
If the buffer is visiting a file, returns the full path to the file.
Returns nil if neither condition is met."
  (cond ((and (fboundp 'dired-current-directory)
              (derived-mode-p 'dired-mode))
         ;; Return the directory name
         (dired-current-directory))

        (t
         (let ((file-name (buffer-file-name (buffer-base-buffer))))
           (if file-name
               ;; Return the file name
               file-name
             ;; Return nil if no condition is met
             nil)))))

;;;###autoload
(defun pathaction-edit ()
  "Edit the pathaction.yaml file."
  (interactive)
  (let* ((file-list (shell-command-to-string "pathaction -l ."))
         (file-list-lines (split-string file-list "\n" t))
         (existing-files '())
         (selected-file nil))
    ;; Filter out non-existing files
    (dolist (file file-list-lines)
      (when (and (not (string-empty-p file)) (file-exists-p file))
        (push file existing-files)))

    ;; Reverse to maintain original order
    (setq existing-files (reverse existing-files))
    (if existing-files
        (progn
          (setq selected-file (completing-read "Select a file: "
                                               existing-files))
          (find-file selected-file))
      (error "No existing files available to edit"))))

;;;###autoload
(defun pathaction-run (tag)
  "Execute a pathaction action identified by TAG.
Prompts the user for a TAG and executes the corresponding pathaction command.
If invoked in a file buffer, uses the file's directory as the target.
If invoked in a Dired buffer, uses the Dired directory.
Signals an error if neither context is met.

The command opens a terminal buffer named based on the TAG and the file or
directory being processed."
  (interactive "sAction: ")
  (let ((file-name (pathaction--buffer-path)))
    (unless file-name
      (error "The command cannot be executed in the current mode"))
    (let* ((directory (file-name-directory file-name))
           (base-name (file-name-nondirectory file-name))
           (command (when directory
                      (concat "pathaction"
                              " "
                              "--confirm-after "
                              "--tag "
                              (shell-quote-argument tag)
                              " "
                              (shell-quote-argument directory)))))
      (when command
        (pathaction--ansi-term command
                               (format "pathaction:%s-%s" tag base-name))))))

(provide 'pathaction)
;;; pathaction.el ends here
