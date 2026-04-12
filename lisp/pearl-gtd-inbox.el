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
  "List of (list original-headline target-file properties-string new-headline remarks) pending to be moved after staging.
If target-file is nil, means delete (trash).
Properties-string contains tags and properties.
New-headline is the clarified headline (nil if unchanged).
Remarks is the clarified remarks text (nil if none).")

(defvar pearl-gtd-inbox-stage-buffer-name nil
  "The name of the current inbox staging buffer.")

(defun pearl-gtd-inbox-capture ()
  "Capture a new item to the inbox with a timestamp."
  (let ((item (read-string "Enter item to capture: ")))
    (with-current-buffer (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
      (goto-char (point-max))
      (insert (format "* %s\n:PROPERTIES:\n:CREATED: %s\n:END:\n" item (format-time-string "%Y-%m-%d %H:%M:%S")))
      (save-buffer))))

(defun pearl-gtd-inbox-clarify-entry (headline buffer entry-ref)
  "Clarify the entry by asking user to rename or add remarks.
HEADLINE is the current entry heading.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry.
Returns a cons cell (NEW-HEADLINE . REMARKS)."
  (let ((new-headline nil)
        (remarks nil))
    ;; Ask for rename
    (let ((rename (read-string (format "Rename '%s'? (RET to keep, or type new name): " headline))))
      (when (not (string= rename ""))
        (setq new-headline rename)
        (pearl-gtd-table-stage-stage-change entry-ref 1 rename)))
    ;; Ask for remarks
    (let ((remark-text (read-string (format "Add remarks for '%s'? (RET to skip, or type remarks): " (or new-headline headline)))))
      (when (not (string= remark-text ""))
        (setq remarks remark-text)
        ;; Update stage buffer to show remarks in column 4
        (pearl-gtd-table-stage-stage-change entry-ref 4 remark-text)))
    (cons new-headline remarks)))

(defun pearl-gtd-inbox-process-entry (headline buffer entry-ref)
  "Process a single entry according to GTD steps.
HEADLINE is the entry heading to process.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry."
  ;; Step 1: Clarify - ask for rename and remarks
  (let* ((clarify-result (pearl-gtd-inbox-clarify-entry headline buffer entry-ref))
         (new-headline (car clarify-result))
         (remarks (cdr clarify-result))
         (display-headline (or new-headline headline)))
    ;; Step 2: Process - check if actionable
    (let ((is-actionable (y-or-n-p (format "Is '%s' actionable? " display-headline))))
      (if is-actionable
          (pearl-gtd-inbox-handle-actionable headline buffer entry-ref new-headline remarks)
        (pearl-gtd-inbox-handle-non-actionable headline buffer entry-ref new-headline remarks)))))

(defun pearl-gtd-inbox-handle-actionable (headline buffer entry-ref new-headline remarks)
  "Handle actionable entries.
HEADLINE is the original entry heading.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry.
NEW-HEADLINE is the clarified headline (nil if unchanged).
REMARKS is the clarified remarks text (nil if none)."
  (let ((can-do-in-2min (y-or-n-p (format "Can '%s' be done in 2 minutes? " (or new-headline headline)))))
    (if can-do-in-2min
        (pearl-gtd-inbox-execute-immediately headline buffer entry-ref new-headline remarks)
      (pearl-gtd-inbox-handle-further-checks headline buffer entry-ref new-headline remarks))))

(defun pearl-gtd-inbox-execute-immediately (headline buffer entry-ref new-headline remarks)
  "Execute and stage immediate actions.
HEADLINE is the original entry heading.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry.
NEW-HEADLINE is the clarified headline (nil if unchanged).
REMARKS is the clarified remarks text (nil if none)."
  (message "Executing '%s' immediately." (or new-headline headline))
  (pearl-gtd-table-stage-mark-executed entry-ref)
  (push (list headline nil nil new-headline remarks) pearl-gtd-inbox--pending-moves))

(defun pearl-gtd-inbox-handle-further-checks (headline buffer entry-ref new-headline remarks)
  "Handle further checks for non-immediate actionable entries.
HEADLINE is the original entry heading.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry.
NEW-HEADLINE is the clarified headline (nil if unchanged).
REMARKS is the clarified remarks text (nil if none)."
  (let ((tags '())
        (display-headline (or new-headline headline)))
    ;; Context: single value
    (let ((context (read-string (format "Context for '%s' (e.g. @home, RET to skip): " display-headline))))
      (when (not (string= context ""))
        (push context tags)))

    ;; Schedule: single value
    (let ((schedule (read-string (format "Schedule for '%s' (e.g. 2026-04-10, RET to skip): " display-headline))))
      (when (not (string= schedule ""))
        (push (format ":SCHEDULED:%s:" schedule) tags)))

    ;; Delegated: single value
    (let ((delegatee (read-string (format "Delegate '%s' to (e.g. John, RET to skip): " display-headline))))
      (when (not (string= delegatee ""))
        (push (format ":DELEGATED:%s:" delegatee) tags)))

    ;; Project: supports multiple projects (comma separated)
    (let ((project-input (read-string (format "Project name(s) for '%s' (comma separated, RET to skip): " display-headline))))
      (let ((projects (mapcar #'string-trim (split-string project-input "," t))))
        (when projects
          (push (format ":PROJECT:%s:" (mapconcat 'identity projects ",")) tags))))

    (let ((props (when tags (mapconcat 'identity (nreverse tags) " "))))
      (when props
        (pearl-gtd-table-stage-stage-change entry-ref 3 props))
      ;; Store headline, target-file, and properties, plus clarify info
      (push (list headline "actions.org" props new-headline remarks) pearl-gtd-inbox--pending-moves))))

(defun pearl-gtd-inbox-handle-non-actionable (headline buffer entry-ref new-headline remarks)
  "Handle non-actionable entries.
HEADLINE is the original entry heading.
BUFFER is the staging buffer.
ENTRY-REF is the reference to the entry.
NEW-HEADLINE is the clarified headline (nil if unchanged).
REMARKS is the clarified remarks text (nil if none)."
  (let ((assign-to (read-string (format "Assign '%s' to (reference, someday, trash): " (or new-headline headline)))))
    (cond
     ((string= assign-to "reference")
      (pearl-gtd-table-stage-stage-change entry-ref 1 (format "[Reference] %s" (or new-headline headline)))
      (push (list headline "reference.org" nil new-headline remarks) pearl-gtd-inbox--pending-moves))
     ((string= assign-to "someday")
      (pearl-gtd-table-stage-stage-change entry-ref 1 (format "[Someday] %s" (or new-headline headline)))
      (push (list headline "someday.org" nil new-headline remarks) pearl-gtd-inbox--pending-moves))
     ((string= assign-to "trash")
      (pearl-gtd-table-stage-mark-deleted entry-ref)
      (push (list headline nil nil new-headline remarks) pearl-gtd-inbox--pending-moves))
     (t nil))))

(defun pearl-gtd-inbox-process ()
  "Process the inbox according to GTD clarify and organize steps, with user interaction via staging buffer."
  (let ((inbox-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
    (setq pearl-gtd-inbox--pending-moves '())
    (when (and pearl-gtd-inbox-stage-buffer-name (get-buffer pearl-gtd-inbox-stage-buffer-name))
      (kill-buffer pearl-gtd-inbox-stage-buffer-name))
    (if (file-exists-p inbox-file)
        (let* ((attrs (file-attributes inbox-file))
               (file-size (file-attribute-size attrs)))
          (if (> file-size 0)
              (let ((staging-buffer (pearl-gtd-table-stage-create inbox-file " *inbox-processing*")))
                (setq pearl-gtd-inbox-stage-buffer-name (buffer-name staging-buffer))
                (with-current-buffer staging-buffer
                  (org-mode)
                  (pearl-gtd-table-stage-map-entries
                   staging-buffer
                   (lambda (headline entry-ref)
                     (pearl-gtd-table-stage-highlight-entry entry-ref)
                     (pearl-gtd-inbox-process-entry headline staging-buffer entry-ref)))
                  ;; Clear highlight after processing all entries
                  (when pearl-gtd-table-stage-current-highlight
                    (delete-overlay pearl-gtd-table-stage-current-highlight)
                    (setq pearl-gtd-table-stage-current-highlight nil))
                  (pearl-gtd-table-stage-clear-changes staging-buffer)
                  (setq pearl-gtd-inbox--pending-moves (nreverse pearl-gtd-inbox--pending-moves))
                  (dolist (move pearl-gtd-inbox--pending-moves)
                    (pearl-gtd-inbox-do-move (nth 0 move) (nth 1 move) (nth 2 move) (nth 3 move) (nth 4 move)))
                  (when (and (file-exists-p inbox-file)
                             (= 0 (file-attribute-size (file-attributes inbox-file))))
                    (delete-file inbox-file)))
                (message "Inbox processing complete and changes applied per GTD workflow."))
            (message "Inbox is empty, nothing to process.")))
      (message "Inbox file does not exist."))))

(defun pearl-gtd-inbox-do-move (headline target-file properties-string new-headline remarks)
  "Move HEADLINE to TARGET-FILE and delete from inbox.
If TARGET-FILE is nil, just delete from inbox (trash).
PROPERTIES-STRING contains properties such as \":SCHEDULED:2026-04-10:\",
\":DELEGATED:John:\", and \":PROJECT:Proj1,Proj2:\",
as well as tags like \"@office\".
HEADLINE is the entry heading to process.
TARGET-FILE is the destination file.
PROPERTIES-STRING is the string of properties.
NEW-HEADLINE is the clarified headline (nil if unchanged).
REMARKS is the clarified remarks text (nil if none)."
  (let ((inbox-path (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
        subtree-content)
    ;; First, add properties and tags to the entry in inbox
    (when (and properties-string (not (string= properties-string "")))
      (with-current-buffer (find-file-noselect inbox-path)
        (org-mode)
        (goto-char (point-min))
        (when (re-search-forward (concat "^\\*+ " (regexp-quote headline) "\\($\\| \\)") nil t)
          (beginning-of-line)
          ;; Parse components separated by space
          (let ((components (split-string properties-string " " t)))
            (dolist (comp components)
              (cond
               ;; SCHEDULED is built-in property, use org-schedule, not in PROPERTIES drawer
               ((string-match "^:SCHEDULED:\\(.+\\):$" comp)
                (let ((date-str (match-string 1 comp)))
                  (org-schedule nil date-str)))
               ;; PROJECT uses multivalued property (supports multiple projects)
               ((string-match "^:PROJECT:\\(.+\\):$" comp)
                (let ((projects (match-string 1 comp)))
                  (dolist (proj (split-string projects "," t))
                    (org-entry-add-to-multivalued-property
                     nil "PROJECT" (string-trim proj)))))
               ;; Other property format: :KEY:VALUE: (excluding SCHEDULED and PROJECT)
               ((string-match "^:\\([^:]+\\):\\(.+\\):$" comp)
                (let ((prop-name (match-string 1 comp))
                      (prop-value (match-string 2 comp)))
                  (org-set-property prop-name prop-value)))
               ;; Context tag format: @context - remove @ and set as only tag (overwrite old)
               ((string-match "^@\\(.+\\)$" comp)
                (let ((tag (match-string 1 comp)))
                  (org-set-tags-to (list tag))))
               ;; Simple tag without @ (fallback, also ensure unique)
               ((not (string-match "^:" comp))
                (org-set-tags-to (list comp))))))
          (save-buffer))))
    ;; Then, extract the subtree from inbox (now with properties)
    (with-current-buffer (find-file-noselect inbox-path)
      (org-mode)
      (goto-char (point-min))
      (when (re-search-forward (concat "^\\*+ " (regexp-quote headline) "\\($\\| \\)") nil t)
        (beginning-of-line)
        ;; Apply headline rename using org-edit-headline to preserve tags
        (when new-headline
          (org-edit-headline new-headline))
        ;; Apply remarks if provided (add as body text after properties drawer)
        (when remarks
          (org-end-of-meta-data t)
          (unless (bolp)
            (insert "\n"))
          (insert remarks "\n"))
        ;; Re-locate to headline start after modifications
        (goto-char (point-min))
        (re-search-forward (concat "^\\*+ " (regexp-quote (or new-headline headline)) "\\($\\| \\)") nil t)
        (beginning-of-line)
        (org-mark-subtree)
        (setq subtree-content (buffer-substring (region-beginning) (region-end)))
        (kill-region (region-beginning) (region-end))
        (save-buffer)))
    ;; Then, insert to target file if needed
    (when (and target-file subtree-content)
      (let ((target-path (expand-file-name target-file pearl-gtd-init-base-directory)))
        (with-current-buffer (find-file-noselect target-path)
          (org-mode)
          (goto-char (point-max))
          (unless (bolp) (insert "\n"))
          (insert subtree-content)
          (unless (bolp) (insert "\n"))
          (save-buffer))))))

(provide 'pearl-gtd-inbox)

;;; pearl-gtd-inbox.el ends here
