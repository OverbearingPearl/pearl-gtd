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

(defvar pearl-gtd-table-stage-original-file nil
  "The original Org file path for the staging buffer.")

(defvar pearl-gtd-table-stage-changes nil
  "A list to store staged changes, e.g., ((row col new-value) ...).")

(defun pearl-gtd-table-stage-create (file-path &optional buffer-name)
  "Create a read-only buffer from the Org FILE-PATH and display its tables.
Optional BUFFER-NAME specifies the buffer name; if nil, a default name is used."
  (setq pearl-gtd-table-stage-original-file file-path)
  (setq pearl-gtd-table-stage-changes nil)
  (let ((actual-buffer-name (or buffer-name (generate-new-buffer-name " *pearl-gtd-table-stage*"))))
    (with-current-buffer (get-buffer-create actual-buffer-name)
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert-file-contents file-path)
      (org-mode)
      (goto-char (point-min))
      (while (re-search-forward org-table-line-regexp nil t)
        (when (org-at-table-p)
          (org-table-align)
          (forward-line 1)))
      (setq buffer-read-only t)
      (use-local-map (copy-keymap org-mode-map))
      (local-set-key (kbd "C-c C-s") 'pearl-gtd-table-stage-stage-change)
      (local-set-key (kbd "C-c C-a") 'pearl-gtd-table-stage-apply-changes)
      (display-buffer (current-buffer))
      (current-buffer))))  ; Return the buffer object

(defun pearl-gtd-table-stage-highlight-current-entry (buffer position)
  "Highlight the entry at POSITION in the staging BUFFER."
  (with-current-buffer buffer
    (save-excursion
      (goto-char position)
      (let ((ov (make-overlay (line-beginning-position) (line-end-position))))
        (overlay-put ov 'face '(:background "yellow"))
        (overlay-put ov 'evaporate t)))))

(defun pearl-gtd-table-stage-add-annotation (buffer position annotation)
  "Add ANNOTATION visually at POSITION in the staging BUFFER."
  (with-current-buffer buffer
    (let ((inhibit-read-only t))  ; Temporarily allow modifications
      (save-excursion
        (goto-char position)
        (insert (format " => %s" annotation))))))

(defun pearl-gtd-table-stage-stage-change (buffer row col new-value)
  "Stage a change for ROW, COL with NEW-VALUE in BUFFER."
  (with-current-buffer buffer
    (push (list row col new-value) pearl-gtd-table-stage-changes)
    (save-excursion
      (org-table-goto-line row)
      (org-table-goto-column col)
      (let ((ov (make-overlay (point) (line-end-position))))
        (overlay-put ov 'face '(:background "yellow"))
        (overlay-put ov 'evaporate t)))))

(defun pearl-gtd-table-stage-apply-changes (buffer)
  "Apply staged changes to the original Org file from BUFFER."
  (with-current-buffer buffer
    (when pearl-gtd-table-stage-original-file
      (with-temp-file pearl-gtd-table-stage-original-file
        (insert-file-contents pearl-gtd-table-stage-original-file)
        (org-mode)
        (goto-char (point-min))
        (dolist (change pearl-gtd-table-stage-changes)
          (let ((row (nth 0 change))
                (col (nth 1 change))
                (new-value (nth 2 change)))
            (when (and (org-at-table-p)
                       (org-table-goto-line row)
                       (org-table-goto-column col))
              (org-table-blank-field)
              (insert new-value)
              (org-table-align))))
        (write-region (point-min) (point-max) pearl-gtd-table-stage-original-file))
      (message "Changes applied to %s" pearl-gtd-table-stage-original-file)
      (setq pearl-gtd-table-stage-changes nil))))

(provide 'pearl-gtd-table-stage)

;;; pearl-gtd-table-stage.el ends here
