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

(defface pearl-gtd-table-stage-highlight
  '((t :inherit highlight))
  "Face for highlighting the current entry in the staging buffer."
  :group 'pearl-gtd)

(defface pearl-gtd-table-stage-deleted
  '((t :inherit shadow :strike-through t))
  "Face for deleted (trash) entries."
  :group 'pearl-gtd)

(defface pearl-gtd-table-stage-executed
  '((t :inherit success :strike-through t))
  "Face for executed (2-minute rule) entries."
  :group 'pearl-gtd)

(defvar pearl-gtd-table-stage-original-file nil
  "The original Org file path for the staging buffer.")

(defvar pearl-gtd-table-stage-changes nil
  "A list to store staged changes, e.g., ((row col new-value) ...).")

(defvar-local pearl-gtd-table-stage-current-highlight nil
  "Current highlight overlay in the staging buffer.")

(defvar-local pearl-gtd-table-stage-marked-deleted-rows '()
  "Buffer-local list of row numbers marked as deleted.")

(defvar-local pearl-gtd-table-stage-marked-executed-rows '()
  "Buffer-local list of row numbers marked as executed.")

(defun pearl-gtd-table-stage-create (file-path &optional buffer-name)
  "Create a read-only buffer from the Org FILE-PATH and convert headlines to a table.
Optional BUFFER-NAME specifies the buffer name; if nil, a default name is used."
  (setq pearl-gtd-table-stage-original-file file-path)
  (setq pearl-gtd-table-stage-changes nil)
  (setq pearl-gtd-table-stage-marked-deleted-rows '())
  (setq pearl-gtd-table-stage-marked-executed-rows '())
  (let ((actual-buffer-name (or buffer-name (generate-new-buffer-name " *pearl-gtd-table-stage*")))
        (headlines '()))
    (with-current-buffer (get-buffer-create actual-buffer-name)
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert-file-contents file-path)
      (org-mode)
      ;; Collect headlines, tags, states and created time
      (org-map-entries
       (lambda ()
         (let* ((headline (org-get-heading t t))
                (tags (org-get-tags-at))
                (state (org-get-todo-state))
                (created (org-entry-get nil "CREATED")))
           (push (list headline tags state created) headlines))))
      ;; Clear buffer and insert only the table
      (erase-buffer)
      (insert "| Headline | Age | Tags |\n")
      (insert "|----------+-----+------|\n")
      (dolist (entry (nreverse headlines))
        (let* ((created-str (nth 3 entry))
               (age-str (if created-str
                          (let* ((created-time (date-to-time created-str))
                                 (diff (time-subtract (current-time) created-time))
                                 (total-seconds (floor (float-time diff)))
                                 (days (/ total-seconds 86400))
                                 (hours (/ (% total-seconds 86400) 3600))
                                 (minutes (/ (% total-seconds 3600) 60)))
                            (format "%dd %dh %dm" days hours minutes))
                        "N/A")))
          (insert (format "| %s | %s | %s |\n"
                          (nth 0 entry)
                          age-str
                          (mapconcat 'identity (nth 1 entry) ",")))))
      (org-table-align)
      (setq buffer-read-only t)
      (use-local-map (copy-keymap org-mode-map))
      (local-set-key (kbd "C-c C-s") 'pearl-gtd-table-stage-stage-change)
      (local-set-key (kbd "C-c C-a") 'pearl-gtd-table-stage-clear-changes)
      (display-buffer (current-buffer))
      (current-buffer))))  ; Return the buffer object

(defun pearl-gtd-table-stage-map-entries (buffer func)
  "Map over all data entries in the staging BUFFER, calling FUNC for each.
FUNC receives two arguments: the HEADLINE text and an ENTRY-REF object.
ENTRY-REF is an opaque reference that can be passed to other pearl-gtd-table-stage functions."
  (with-current-buffer buffer
    (save-excursion
      (goto-char (point-min))
      (forward-line 2)
      (let ((entries '()))
        (while (not (eobp))
          (let ((current-row (line-number-at-pos)))
            (when (looking-at "|")
              (let ((headline (string-trim (org-table-get-field 1))))
                (when (and headline (not (string= headline "")))
                  (push (cons headline (cons buffer current-row)) entries)))))
          (forward-line 1))
        (dolist (entry (nreverse entries))
          (funcall func (car entry) (cdr entry)))))))

(defun pearl-gtd-table-stage-highlight-entry (entry-ref)
  "Highlight the entry referenced by ENTRY-REF."
  (let ((buffer (car entry-ref))
        (row (cdr entry-ref)))
    (with-current-buffer buffer
      (save-excursion
        (when pearl-gtd-table-stage-current-highlight
          (delete-overlay pearl-gtd-table-stage-current-highlight)
          (setq pearl-gtd-table-stage-current-highlight nil))
        (goto-char (point-min))
        (forward-line (1- row))
        (let ((ov (make-overlay (line-beginning-position) (line-end-position))))
          (overlay-put ov 'face 'pearl-gtd-table-stage-highlight)
          (overlay-put ov 'evaporate t)
          (setq pearl-gtd-table-stage-current-highlight ov))))))

(defun pearl-gtd-table-stage-add-annotation (entry-ref annotation)
  "Add ANNOTATION to the entry referenced by ENTRY-REF."
  (let ((buffer (car entry-ref))
        (row (cdr entry-ref)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- row))
          (end-of-line)
          (insert (format " => %s" annotation))
          (org-table-align))))))

(defun pearl-gtd-table-stage-mark-deleted (entry-ref)
  "Mark the entry referenced by ENTRY-REF as deleted (trash)."
  (let ((buffer (car entry-ref))
        (row (cdr entry-ref)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- row))
          (org-table-goto-column 1)
          (let* ((start (point))
                 (end (progn (skip-chars-forward "^|") (point)))
                 (ov (make-overlay start end)))
            (overlay-put ov 'face 'pearl-gtd-table-stage-deleted)
            (overlay-put ov 'evaporate t)))
        (cl-pushnew row pearl-gtd-table-stage-marked-deleted-rows)))))

(defun pearl-gtd-table-stage-mark-executed (entry-ref)
  "Mark the entry referenced by ENTRY-REF as executed (2min rule)."
  (let ((buffer (car entry-ref))
        (row (cdr entry-ref)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- row))
          (org-table-goto-column 1)
          (let* ((start (point))
                 (end (progn (skip-chars-forward "^|") (point)))
                 (ov (make-overlay start end)))
            (overlay-put ov 'face 'pearl-gtd-table-stage-executed)
            (overlay-put ov 'evaporate t)))
        (cl-pushnew row pearl-gtd-table-stage-marked-executed-rows)))))

(defun pearl-gtd-table-stage-stage-change (entry-ref col new-value)
  "Stage a change for ENTRY-REF at COL with NEW-VALUE."
  (let ((buffer (car entry-ref))
        (row (cdr entry-ref)))
    (with-current-buffer buffer
      (push (list row col new-value) pearl-gtd-table-stage-changes)
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- row))
          (org-table-goto-column col)
          (org-table-blank-field)
          (insert new-value)
          (org-table-align)
          (pearl-gtd-table-stage--reapply-marks buffer))))))

(defun pearl-gtd-table-stage-clear-changes (buffer)
  "Clear the changes list without writing back to the file."
  (with-current-buffer buffer
    (setq pearl-gtd-table-stage-changes nil)
    (message "Changes cleared.")))

(defun pearl-gtd-table-stage--reapply-marks (buffer)
  "Reapply all marks to BUFFER after table alignment."
  (with-current-buffer buffer
    (dolist (row pearl-gtd-table-stage-marked-deleted-rows)
      (condition-case nil
          (progn
            (goto-char (point-min))
            (forward-line (1- row))
            (org-table-goto-column 1)
            (let* ((start (point))
                   (end (progn (skip-chars-forward "^|") (point)))
                   (ov (make-overlay start end)))
              (overlay-put ov 'face 'pearl-gtd-table-stage-deleted)
              (overlay-put ov 'evaporate t)))
        (error nil)))
    (dolist (row pearl-gtd-table-stage-marked-executed-rows)
      (condition-case nil
          (progn
            (goto-char (point-min))
            (forward-line (1- row))
            (org-table-goto-column 1)
            (let* ((start (point))
                   (end (progn (skip-chars-forward "^|") (point)))
                   (ov (make-overlay start end)))
              (overlay-put ov 'face 'pearl-gtd-table-stage-executed)
              (overlay-put ov 'evaporate t)))
        (error nil)))))

(provide 'pearl-gtd-table-stage)

;;; pearl-gtd-table-stage.el ends here
