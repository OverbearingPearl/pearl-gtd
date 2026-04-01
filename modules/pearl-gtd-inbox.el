;;; modules/pearl-gtd-inbox.el --- Inbox handling for pearl-gtd  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4") (pearl-gtd-table-stage "0.1.0"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file handles inbox-related functions for pearl-gtd, including capture and processing.

;;; Code:

(require 'pearl-gtd-table-stage)  ; Depend on the infrastructure module

(defun pearl-gtd-inbox-capture ()
  "Interactively capture a new item to the inbox with a timestamp."
  (interactive)
  (let ((item (read-string "Enter item to capture: ")))
    (with-current-buffer (find-file-noselect (expand-file-name "inbox.org" "~/.pearl-gtd/"))
      (goto-char (point-max))
      (insert (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n" item (format-time-string "%Y-%m-%d %H:%M:%S")))
      (save-buffer))))

(defun pearl-gtd-inbox-process ()
  "Process the inbox using the table staging buffer."
  (let ((inbox-file (expand-file-name "inbox.org" "~/.pearl-gtd/")))
    (pearl-gtd-table-stage-create inbox-file)
    (message "Processing inbox... Use the staging buffer to make changes.")))

(provide 'pearl-gtd-inbox)

;;; modules/pearl-gtd-inbox.el ends here
