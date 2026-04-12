;;; test-pearl-gtd-clarify.el --- User stories: Clarify phase  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; User stories for clarifying inbox items.

;;; Code:

(require 'ert)
(require 'pearl-gtd)
(require 'test-pearl-gtd-macros)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-clarify-user-renames-unclear-task
    "User renames 'Stuff' to 'Buy birthday gift for mom' during processing."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Stuff\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "Buy birthday gift for mom")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Assign" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (progn
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "reference.org" pearl-gtd-init-base-directory)
                      "* Buy birthday gift for mom"))
             (should (test-pearl-gtd-file-lacks-p
                      (expand-file-name "reference.org" pearl-gtd-init-base-directory)
                      "* Stuff")))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-clarify-user-adds-notes-to-task
    "User adds 'Check Amazon first' as notes to a task."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Research laptop\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "Check Amazon first")
             ((string-match "Assign" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (test-pearl-gtd-file-contains-p
            (expand-file-name "reference.org" pearl-gtd-init-base-directory)
            "Check Amazon first")
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-clarify-user-skips-all-clarifications
    "User skips all clarifications during processing."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Simple task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Assign" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "reference.org" pearl-gtd-init-base-directory)
                    "* Simple task"))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-clarify-user-cancels-midway
    "User cancels midway during clarification."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task to cancel\n"))
  :mock nil  ; Assuming cancellation logic
  :body (signal 'quit nil)  ; Simulate cancellation
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    "* Task to cancel"))
  :teardown nil)

(provide 'test-pearl-gtd-clarify)

;;; test-pearl-gtd-clarify.el ends here
