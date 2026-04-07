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

(defvar pearl-gtd-inbox--pending-moves nil
  "List of (headline . target-file) pending to be moved after staging.
If target-file is nil, means delete (trash).")

(defvar pearl-gtd-inbox-stage-buffer-name nil
  "The name of the current inbox staging buffer.")

(defun pearl-gtd-inbox-capture ()
  "Capture a new item to the inbox with a timestamp."
  (let ((item (read-string "Enter item to capture: ")))
    (with-current-buffer (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
      (goto-char (point-max))
      (insert (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n" item (format-time-string "%Y-%m-%d %H:%M:%S")))
      (save-buffer))))

(defun pearl-gtd-inbox-process-entry (headline buffer row)
  "Process a single entry according to GTD steps.
HEADLINE is the entry heading to process. BUFFER is the staging buffer. ROW is the row number."
  (let ((is-actionable (y-or-n-p (format "Is '%s' actionable? " headline))))
    (if is-actionable
        (pearl-gtd-inbox-handle-actionable headline buffer row)
      (pearl-gtd-inbox-handle-non-actionable headline buffer row))))

(defun pearl-gtd-inbox-handle-actionable (headline buffer row)
  "Handle actionable entries.
HEADLINE is the entry heading to process. BUFFER is the staging buffer. ROW is the row number."
  (let ((can-do-in-2min (y-or-n-p (format "Can '%s' be done in 2 minutes? " headline))))
    (if can-do-in-2min
        (pearl-gtd-inbox-execute-immediately headline buffer row)
      (pearl-gtd-inbox-handle-further-checks headline buffer row))))

(defun pearl-gtd-inbox-execute-immediately (headline buffer row)
  "Execute and stage immediate actions."
  (message "Executing '%s' immediately." headline)
  (pearl-gtd-table-stage-mark-executed buffer row)
  (push (cons headline nil) pearl-gtd-inbox--pending-moves))

(defun pearl-gtd-inbox-handle-further-checks (headline buffer row)
  "Handle further checks for non-immediate actionable entries.
HEADLINE is the entry heading to check. BUFFER is the staging buffer. ROW is the row number."
  (let ((tags '()))
    (let ((context (read-string (format "Context for '%s' (e.g. @home, @office, RET to skip): " headline))))
      (when (not (string= context ""))
        (push context tags)))

    (let ((schedule (read-string (format "Schedule for '%s' (e.g. 2026-04-10, RET to skip): " headline))))
      (when (not (string= schedule ""))
        (push (format ":SCHEDULED:%s:" schedule) tags)))

    (let ((delegatee (read-string (format "Delegate '%s' to (e.g. John, RET to skip): " headline))))
      (when (not (string= delegatee ""))
        (push (format ":DELEGATED:%s:" delegatee) tags)))

    (let ((project-name (read-string (format "Project name for '%s' (RET to skip): " headline))))
      (when (not (string= project-name ""))
        (push (format ":PROJECT:%s:" project-name) tags)))

    (when tags
      (pearl-gtd-table-stage-stage-change buffer row 2 (mapconcat 'identity (nreverse tags) " "))))

  ;; Move actionable items to actions.org after tagging
  (push (cons headline "actions.org") pearl-gtd-inbox--pending-moves))

(defun pearl-gtd-inbox-handle-non-actionable (headline buffer row)
  "Handle non-actionable entries.
HEADLINE is the entry heading to handle. BUFFER is the staging buffer. ROW is the row number."
  (let ((assign-to (read-string (format "Assign '%s' to (reference, someday, trash): " headline))))
    (cond
     ((string= assign-to "reference")
      (pearl-gtd-table-stage-add-annotation buffer row "-> reference")
      (push (cons headline "reference.org") pearl-gtd-inbox--pending-moves))
     ((string= assign-to "someday")
      (pearl-gtd-table-stage-add-annotation buffer row "-> someday")
      (push (cons headline "someday.org") pearl-gtd-inbox--pending-moves))
     ((string= assign-to "trash")
      (pearl-gtd-table-stage-mark-deleted buffer row)
      (push (cons headline nil) pearl-gtd-inbox--pending-moves))
     (t (pearl-gtd-table-stage-add-annotation buffer row "No change")))))

(defun pearl-gtd-inbox-process ()
  "Process the inbox according to GTD clarify and organize steps, with user interaction via staging buffer."
  (let ((inbox-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
    (setq pearl-gtd-inbox--pending-moves '())
    (when (get-buffer pearl-gtd-inbox-stage-buffer-name)
      (kill-buffer pearl-gtd-inbox-stage-buffer-name))
    (if (file-exists-p inbox-file)
        (let* ((attrs (file-attributes inbox-file))
               (file-size (file-attribute-size attrs)))
          (if (> file-size 0)
              (let ((staging-buffer (pearl-gtd-table-stage-create inbox-file " *custom-inbox-stage*")))
                (setq pearl-gtd-inbox-stage-buffer-name (buffer-name staging-buffer))
                (with-current-buffer staging-buffer
                  (org-mode)
                  (pearl-gtd-table-stage-map-entries
                   staging-buffer
                   (lambda (headline row)
                     (pearl-gtd-table-stage-highlight-entry staging-buffer row)
                     (pearl-gtd-inbox-process-entry headline staging-buffer row)))
                  (pearl-gtd-table-stage-apply-changes staging-buffer)
                  (dolist (move pearl-gtd-inbox--pending-moves)
                    (pearl-gtd-inbox-do-move (car move) (cdr move)))
                  (when (and (file-exists-p inbox-file)
                             (= 0 (file-attribute-size (file-attributes inbox-file))))
                    (delete-file inbox-file)))
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

(defun pearl-gtd-inbox-do-move (headline target-file)
  "Move HEADLINE to TARGET-FILE and delete from inbox.
If TARGET-FILE is nil, just delete from inbox (trash)."
  (let ((inbox-path (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
    (with-current-buffer (find-file-noselect inbox-path)
      (org-mode)
      (goto-char (point-min))
      (when (search-forward (concat "* " headline) nil t)
        (beginning-of-line)
        (org-mark-subtree)
        (kill-region (region-beginning) (region-end))
        (save-buffer)))
    (when target-file
      (let ((target-path (expand-file-name target-file pearl-gtd-init-base-directory)))
        (with-current-buffer (find-file-noselect target-path)
          (org-mode)
          (goto-char (point-max))
          (insert (format "* %s\n" headline))
          (save-buffer))))))

(provide 'pearl-gtd-inbox)

;;; pearl-gtd-inbox.el ends here
