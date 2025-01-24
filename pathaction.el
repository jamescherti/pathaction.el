;;; pathaction.el --- Execute pathaction.yaml rules using pathaction  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 0.9.9
;; URL: https://github.com/jamescherti/pathaction.el
;; Keywords: convenience
;; Package-Requires: ((emacs "24.1"))
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
  "Execute pathaction.yaml rules using pathaction"
  :group 'pathaction
  :prefix "pathaction-"
  :link '(url-link
          :tag "Github"
          "https://github.com/jamescherti/pathaction.el"))

(defun pathaction--message (&rest args)
  "Display a message with '[pathaction]' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] " (car args)) (cdr args)))

(defun pathaction--warning (&rest args)
  "Display a warning message with '[pathaction] Warning: ' prepended.
The message is formatted with the provided arguments ARGS."
  (apply #'message (concat "[pathaction] Warning: " (car args)) (cdr args)))

;;;###autoload
(define-minor-mode pathaction-mode
  "Toggle `pathaction-mode'."
  :global t
  :lighter " pathaction"
  :group 'pathaction
  (if pathaction-mode
      t
    t))

(provide 'pathaction)
;;; pathaction.el ends here
