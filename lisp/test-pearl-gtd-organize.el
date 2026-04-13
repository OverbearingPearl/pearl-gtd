;;; test-pearl-gtd-organize.el --- User stories: Organize phase  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; User stories for organizing items into appropriate categories.

;;; Code:

(require 'ert)
(require 'pearl-gtd)
(require 'test-pearl-gtd-macros)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-trashes-junk-item
    "User decides item is trash, it disappears completely."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Junk item\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Assign" prompt) "trash")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (should (test-pearl-gtd-inbox-empty-p pearl-gtd-init-base-directory))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-files-item-to-reference
    "User moves 'Article about Emacs' to reference.org."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Article about Emacs\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Assign" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (test-pearl-gtd-file-contains-p
            (expand-file-name "reference.org" pearl-gtd-init-base-directory)
            "* Article about Emacs")
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-sets-context-at-office
    "User tags task with @office context."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task for office\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (prompt &rest _)
            (cond
             ((string-match "2 minutes" prompt) nil)
             ((string-match "actionable" prompt) t)
             (t nil))))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Context" prompt) "@office")
             ((string-match "Schedule" prompt) "")
             ((string-match "Delegate" prompt) "")
             ((string-match "Project" prompt) "")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (test-pearl-gtd-file-contains-p
            (expand-file-name "actions.org" pearl-gtd-init-base-directory)
            ":office:")
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-renames-then-sets-context-and-schedule
    "User renames task and sets @office context with schedule."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Old vague name\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (prompt &rest _)
            (cond
             ((string-match "2 minutes" prompt) nil)
             ((string-match "actionable" prompt) t)
             (t nil))))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "Prepare quarterly report")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Context" prompt) "@office")
             ((string-match "Schedule" prompt) "2026-04-15")
             ((string-match "Delegate" prompt) "")
             ((string-match "Project" prompt) "")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (progn
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "* Prepare quarterly report"))
             (should (test-pearl-gtd-file-lacks-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "* Old vague name"))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      ":office:"))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "SCHEDULED"))
             (should (test-pearl-gtd-inbox-empty-p pearl-gtd-init-base-directory)))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-processes-empty-inbox
    "User processes an empty inbox."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" ""))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil)))
  :body (pearl-gtd-process-inbox)
  :asserts (should (test-pearl-gtd-inbox-empty-p pearl-gtd-init-base-directory))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-organize-user-handles-duplicate-titles
    "User processes entries with duplicate titles."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Duplicate task\n* Duplicate task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "Renamed task")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Assign" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "reference.org" pearl-gtd-init-base-directory)
                    "* Renamed task"))
  :teardown nil)

(provide 'test-pearl-gtd-organize)

;;; test-pearl-gtd-organize.el ends here
