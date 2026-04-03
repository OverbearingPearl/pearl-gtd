;;; pearl-gtd-table-stage.el --- Table staging buffer for pearl-gtd  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file provides a read-only buffer for staging changes to Org tables.
;; It interacts with Org files, presents data in tables, and allows staged edits.

;;; Code:

(require 'org)
(require 'org-table)

(defvar pearl-gtd-table-stage-buffer-name " *pearl-gtd-table-stage*"
  "Name of the staging buffer.")

(defvar pearl-gtd-table-stage-original-file nil
  "The original Org file path.")

(defvar pearl-gtd-table-stage-changes nil
  "A list to store staged changes, e.g., ((row col new-value) ...).")

(defun pearl-gtd-table-stage-create (file-path)
  "Create a read-only buffer from the Org FILE-PATH and display its tables."
  (setq pearl-gtd-table-stage-original-file file-path)
  (setq pearl-gtd-table-stage-changes nil)  ; Reset changes
  (with-current-buffer (get-buffer-create pearl-gtd-table-stage-buffer-name)
    (setq buffer-read-only nil)  ; Temporarily make writable to insert content
    (erase-buffer)
    (insert-file-contents file-path)
    (org-mode)  ; Ensure Org mode is active
    (goto-char (point-min))
    (while (re-search-forward "^\\|\\*+ " nil t)
      (org-table-align))  ; Align tables
    (setq buffer-read-only t)  ; Make buffer read-only
    (use-local-map (copy-keymap org-mode-map))  ; Inherit Org map
    (local-set-key (kbd "C-c C-s") 'pearl-gtd-table-stage-stage-change)  ; Example key for staging
    (local-set-key (kbd "C-c C-a") 'pearl-gtd-table-stage-apply-changes)  ; Apply changes
    (display-buffer (current-buffer))))

(defun pearl-gtd-table-stage-stage-change (row col new-value)
  "Stage a change for ROW, COL with NEW-VALUE."
  (push (list row col new-value) pearl-gtd-table-stage-changes)
  ;; Highlight the changed cell for feedback
  (with-current-buffer pearl-gtd-table-stage-buffer-name
    (save-excursion
      (org-table-goto-line row)
      (org-table-goto-column col)
      (let ((ov (make-overlay (point) (line-end-position))))
        (overlay-put ov 'face '(:background "yellow"))  ; Highlight
        (overlay-put ov 'evaporate t)))))  ; Remove after action

(defun pearl-gtd-table-stage-apply-changes ()
  "Apply staged changes to the original Org file."
  (when pearl-gtd-table-stage-original-file
    (with-temp-file pearl-gtd-table-stage-original-file
      (insert-file-contents pearl-gtd-table-stage-original-file)
      (org-mode)
      (goto-char (point-min))
      (dolist (change pearl-gtd-table-stage-changes)
        (let ((row (nth 0 change))
              (col (nth 1 change))
              (new-value (nth 2 change)))
          ;; Go to the first table and apply the change
          (when (and (org-at-table-p)  ; Check if in a table, though we might need to navigate
                     (org-table-goto-line row)
                     (org-table-goto-column col))
            (org-table-blank-field)
            (insert new-value)
            (org-table-align))))
      ;; Save the file
      (write-region (point-min) (point-max) pearl-gtd-table-stage-original-file))
    (message "Changes applied to %s" pearl-gtd-table-stage-original-file)
    (setq pearl-gtd-table-stage-changes nil)))  ; Clear changes

(provide 'pearl-gtd-table-stage)

;;; pearl-gtd-table-stage.el ends here
