;;; pearl-gtd-inbox.el --- Inbox handling for pearl-gtd  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file handles inbox-related functions for pearl-gtd, including capture and processing with user interaction via staging, fully aligned with GTD workflow.

;;; Code:

(require 'pearl-gtd-table-stage)
(require 'org)

(defun pearl-gtd-inbox-capture ()
  "Capture a new item to the inbox with a timestamp."
  (let ((item (read-string "Enter item to capture: ")))
    (with-current-buffer (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
      (goto-char (point-max))
      (insert (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n" item (format-time-string "%Y-%m-%d %H:%M:%S")))
      (save-buffer))))

(defun pearl-gtd-inbox-process-entry (headline)
  "Process a single entry HEADLINE according to GTD steps."
  (let ((is-actionable (y-or-n-p (format "Is '%s' actionable? " headline))))
    (if is-actionable
        (pearl-gtd-inbox-handle-actionable headline)
      (pearl-gtd-inbox-handle-non-actionable headline))))

(defun pearl-gtd-inbox-handle-actionable (headline)
  "Handle actionable entries."
  (let ((can-do-in-2min (y-or-n-p (format "Can '%s' be done in 2 minutes? " headline))))
    (if can-do-in-2min
        (pearl-gtd-inbox-execute-immediately headline)
      (pearl-gtd-inbox-handle-further-checks headline))))

(defun pearl-gtd-inbox-execute-immediately (headline)
  "Execute and stage immediate actions."
  (message "Executing '%s' immediately." headline)
  (pearl-gtd-table-stage-stage-change (point) 0 "done")
  (pearl-gtd-table-stage-add-annotation (point) "Executed and deleted"))

(defun pearl-gtd-inbox-handle-further-checks (headline)
  "Handle further checks for non-immediate actionable entries."
  (let ((is-contextual (y-or-n-p (format "Does '%s' involve a context? " headline)))
        (is-scheduled (y-or-n-p (format "Is '%s' scheduled? " headline)))
        (is-delegated (y-or-n-p (format "Is '%s' delegated? " headline)))
        (is-project (y-or-n-p (format "Is '%s' a project? " headline))))
    (when is-contextual
      (pearl-gtd-table-stage-stage-change (point) 0 ":CONTEXT:")
      (pearl-gtd-table-stage-add-annotation (point) "Added :CONTEXT:"))
    (when is-scheduled
      (pearl-gtd-table-stage-stage-change (point) 0 "SCHEDULED:")
      (pearl-gtd-table-stage-add-annotation (point) "Added SCHEDULED:"))
    (when is-delegated
      (pearl-gtd-table-stage-stage-change (point) 0 ":DELEGATED:")
      (pearl-gtd-table-stage-add-annotation (point) "Added :DELEGATED:"))
    (when is-project
      (pearl-gtd-table-stage-stage-change (point) 0 ":PROJECT:")
      (pearl-gtd-table-stage-add-annotation (point) "Added :PROJECT:"))))

(defun pearl-gtd-inbox-handle-non-actionable (headline)
  "Handle non-actionable entries."
  (let ((assign-to (read-string (format "Assign '%s' to (reference, someday, trash): " headline))))
    (cond
     ((string= assign-to "reference") (pearl-gtd-table-stage-stage-change (point) 0 "reference.org") (pearl-gtd-table-stage-add-annotation (point) "Moved to reference.org"))
     ((string= assign-to "someday") (pearl-gtd-table-stage-stage-change (point) 0 "someday.org") (pearl-gtd-table-stage-add-annotation (point) "Moved to someday.org"))
     ((string= assign-to "trash") (pearl-gtd-table-stage-stage-change (point) 0 "trash") (pearl-gtd-table-stage-add-annotation (point) "Deleted"))
     (t (pearl-gtd-table-stage-add-annotation (point) "No change")))))

(defun pearl-gtd-inbox-process ()
  "Process the inbox according to GTD clarify and organize steps, with user interaction via staging buffer."
  (let ((inbox-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
    (if (file-exists-p inbox-file)
        (let* ((attrs (file-attributes inbox-file))
               (file-size (file-attribute-size attrs)))
          (if (> file-size 0)
              (progn
                (pearl-gtd-table-stage-create inbox-file)
                (with-current-buffer pearl-gtd-table-stage-buffer-name
                  (org-mode)
                  (org-map-entries
                   (lambda ()
                     (let* ((headline (org-get-heading t t)))
                       (pearl-gtd-table-stage-highlight-current-entry (point))
                       (pearl-gtd-inbox-process-entry headline)
                       t))))
                (pearl-gtd-table-stage-apply-changes)
                (message "Inbox processing complete and changes applied per GTD workflow."))
            (message "Inbox is empty, nothing to process.")))
      (message "Inbox file does not exist."))))

(defun pearl-gtd-inbox-is-actionable (headline)
  "Check if HEADLINE is actionable."
  (string-match-p "action" headline))

(defun pearl-gtd-inbox-can-do-in-2min (headline)
  "Check if HEADLINE can be done in 2 minutes."
  (< (length headline) 50))

(defun pearl-gtd-inbox-is-contextual (headline)
  "Check if HEADLINE requires a context."
  (string-match-p ":CONTEXT:" headline))

(defun pearl-gtd-inbox-is-scheduled (headline)
  "Check if HEADLINE is scheduled."
  (org-entry-get nil "SCHEDULED"))

(defun pearl-gtd-inbox-is-delegated (headline)
  "Check if HEADLINE is delegated."
  (string-match-p ":DELEGATED:" headline))

(defun pearl-gtd-inbox-move-to (target-file headline)
  "Move HEADLINE to TARGET-FILE based on staged changes."
  (let ((target-path (expand-file-name target-file pearl-gtd-init-base-directory)))
    (with-current-buffer (find-file-noselect target-path)
      (org-mode)
      (goto-char (point-max))
      (insert (format "* %s\n" headline))
      (save-buffer))
    (with-current-buffer (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
      (org-mark-subtree)
      (kill-region (region-beginning) (region-end))
      (save-buffer))))

(provide 'pearl-gtd-inbox)

;;; pearl-gtd-inbox.el ends here
