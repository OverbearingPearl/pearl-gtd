;;; test-pearl-gtd-inbox.el --- Tests for pearl-gtd-inbox  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file contains tests for pearl-gtd-inbox.

;;; Code:

(require 'ert)
(require 'pearl-gtd-inbox)
(require 'test-pearl-gtd-macros)
(require 'cl-lib)
(require 'pearl-gtd-init)

;; Test capture functionality
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-capture
    "Test basic capture to inbox."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest args) "Test item")))
  :body (pearl-gtd-inbox-capture)
  :asserts (let ((inbox-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
             (with-temp-buffer
               (insert-file-contents inbox-file)
               (should (search-forward "* Test item" nil t))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (delete-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: actionable and can be done in 2 minutes
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-immediate
    "Test processing path: actionable and can be done in 2 minutes."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Quick task\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Quick task" (car args)) "Quick task")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (should-not
             (with-current-buffer
                 (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
               (search-forward "* Quick task" nil t)))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: actionable with context
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-context
    "Test processing path: actionable with context."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task with context\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Context" (car args)) "@office")
              ((string-match "Schedule" (car args)) "")
              ((string-match "Delegate" (car args)) "")
              ((string-match "Project" (car args)) "")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (goto-char (point-min))
                 (forward-line 2)
                 (should (search-forward "@office" (line-end-position) t)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: actionable with scheduled date
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-scheduled
    "Test processing path: actionable with scheduled date."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task with schedule\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Context" (car args)) "")
              ((string-match "Schedule" (car args)) "2026-04-10")
              ((string-match "Delegate" (car args)) "")
              ((string-match "Project" (car args)) "")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (goto-char (point-min))
                 (forward-line 2)
                 (should (search-forward ":SCHEDULED:2026-04-10:" (line-end-position) t)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: actionable with delegation
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-delegated
    "Test processing path: actionable with delegation."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task delegated\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Context" (car args)) "")
              ((string-match "Schedule" (car args)) "")
              ((string-match "Delegate" (car args)) "John")
              ((string-match "Project" (car args)) "")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (goto-char (point-min))
                 (forward-line 2)
                 (should (search-forward ":DELEGATED:John:" (line-end-position) t)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: actionable as a project
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-project
    "Test processing path: actionable as a project."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Project task\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Context" (car args)) "")
              ((string-match "Schedule" (car args)) "")
              ((string-match "Delegate" (car args)) "")
              ((string-match "Project" (car args)) "MyProject")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (goto-char (point-min))
                 (forward-line 2)
                 (should (search-forward ":PROJECT:MyProject:" (line-end-position) t)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: non-actionable to reference
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-reference
    "Test processing path: non-actionable to reference."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Non-actionable task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Assign" (car args)) "reference")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (should (file-exists-p (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "reference.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: non-actionable to someday
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-someday
    "Test processing path: non-actionable to someday."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Someday task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Assign" (car args)) "someday")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (should (file-exists-p (expand-file-name "someday.org" pearl-gtd-init-base-directory)))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "someday.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test processing path: non-actionable to trash
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-trash
    "Test processing path: non-actionable to trash."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Trash task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Assign" (car args)) "trash")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (should-not (file-exists-p (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (delete-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test clarify: rename headline
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-clarify-rename
    "Test clarify step with renaming the headline."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Old name\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "New clarified name")
              ((string-match "Add remarks" (car args)) "")
              ((string-match "Assign" (car args)) "reference")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((ref-file (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
             (should (file-exists-p ref-file))
             (with-temp-buffer
               (insert-file-contents ref-file)
               (should (search-forward "* New clarified name" nil t))
               (should-not (search-forward "* Old name" nil t))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "reference.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test clarify: add remarks
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-clarify-remarks
    "Test clarify step with adding remarks."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task with remarks\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "This is a detailed remark")
              ((string-match "Assign" (car args)) "reference")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((ref-file (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
             (should (file-exists-p ref-file))
             (with-temp-buffer
               (insert-file-contents ref-file)
               (should (search-forward "* Task with remarks" nil t))
               (should (search-forward "This is a detailed remark" nil t))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "reference.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; Test clarify: both rename and remarks
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-clarify-both
    "Test clarify step with both rename and remarks."
  :setup (progn
           (pearl-gtd-init-initialize)
           (let ((ref-file (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
             (with-temp-file ref-file
               (insert ";; reference.org\n"))))
  :files (("inbox.org" "* Original\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "^Rename" (car args)) "Renamed task")
              ((string-match "^Add remarks" (car args)) "Additional context here")
              ((string-match "^Assign" (car args)) "reference")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((ref-file (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
             (should (file-exists-p ref-file))
             (with-temp-buffer
               (insert-file-contents ref-file)
               (goto-char (point-min))
               (should (search-forward "* Renamed task" nil t))
               (should (search-forward "Additional context here" nil t))
               (should-not (search-forward "* Original" nil t))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "reference.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; New test for actionable with properties and remarks
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-properties-and-remarks
    "Test processing actionable entry with properties and remarks, verifying properties drawer order."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Actionable task with properties\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks" (car args)) "This is a detailed remark")
              ((string-match "Context" (car args)) "")
              ((string-match "Schedule" (car args)) "2026-04-10")
              ((string-match "Delegate" (car args)) "")
              ((string-match "Project" (car args)) "MyProject")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((actions-file (expand-file-name "actions.org" pearl-gtd-init-base-directory)))
             (should (file-exists-p actions-file))
             (with-temp-buffer
               (insert-file-contents actions-file)
               (should (search-forward "* Actionable task with properties" nil t))
               (goto-char (point-min))
               (let ((props-start (save-excursion
                                    (when (re-search-forward "^:PROPERTIES:" nil t)
                                      (match-beginning 0))))
                     (remarks-start (save-excursion
                                      (when (re-search-forward "This is a detailed remark" nil t)
                                        (match-beginning 0)))))
                 (should props-start)
                 (should remarks-start)
                 (should (< props-start remarks-start)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

;; New test for processing multiple entries with remarks
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-multiple-entries-with-remarks
    "Test processing multiple entries, ensuring headlines remain intact after adding remarks."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* First task\n* Second task\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "actionable" (car args)) t)
              (t nil))))
         ((symbol-function 'read-string)
          (lambda (&rest args)
            (cond
              ((string-match "Rename" (car args)) "")
              ((string-match "Add remarks.*First task" (car args)) "Remarks for first task")
              ((string-match "Add remarks.*Second task" (car args)) "Remarks for second task")
              ((string-match "Context" (car args)) "")
              ((string-match "Schedule" (car args)) "")
              ((string-match "Delegate" (car args)) "")
              ((string-match "Project" (car args)) "")
              (t "")))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((actions-file (expand-file-name "actions.org" pearl-gtd-init-base-directory)))
             (should (file-exists-p actions-file))
             (with-temp-buffer
               (insert-file-contents actions-file)
               ;; Check first task headline and remarks
               (should (search-forward "* First task" nil t))
               (should (search-forward "Remarks for first task" nil t))
               ;; Ensure no pollution
               (goto-char (point-min))
               (should (search-forward "* First task" nil t))
               ;; Check second task
               (should (search-forward "* Second task" nil t))
               (should (search-forward "Remarks for second task" nil t))
               ;; Verify order: First task before Second task
               (let ((first-pos (save-excursion
                                  (goto-char (point-min))
                                  (search-forward "* First task" nil t)
                                  (point))))
                 (goto-char (point-min))
                 (search-forward "* Second task" nil t)
                 (should (> (point) first-pos)))))
  :teardown (progn
              (when (and pearl-gtd-inbox-stage-buffer-name
                         (get-buffer pearl-gtd-inbox-stage-buffer-name))
                (kill-buffer pearl-gtd-inbox-stage-buffer-name))
              (dolist (file '("inbox.org" "actions.org"))
                (let ((path (expand-file-name file pearl-gtd-init-base-directory)))
                  (when (file-exists-p path)
                    (delete-file path))))
              (setq pearl-gtd-inbox--pending-moves nil)
              (setq pearl-gtd-inbox-stage-buffer-name nil)))

(provide 'test-pearl-gtd-inbox)

;;; test-pearl-gtd-inbox.el ends here
