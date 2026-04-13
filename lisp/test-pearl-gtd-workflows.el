;;; test-pearl-gtd-workflows.el --- User stories: End-to-end workflows  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; Complete user workflows spanning multiple phases.

;;; Code:

(require 'ert)
(require 'pearl-gtd)
(require 'test-pearl-gtd)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-workflows-user-processes-full-gtd-pipeline
    "User captures, clarifies, organizes, and completes processing."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Enter item" prompt) "Buy birthday gift")
             ((string-match "Rename" prompt) "Buy gift for mom")
             ((string-match "Add remarks" prompt) "Check Amazon first")
             ((string-match "Context" prompt) "@errands")
             ((string-match "Schedule" prompt) "")
             ((string-match "Delegate" prompt) "")
             ((string-match "Project" prompt) "")
             (t ""))))
         ((symbol-function 'y-or-n-p)
          (lambda (prompt &rest _)
            (cond
             ((string-match "2 minutes" prompt) nil)
             ((string-match "actionable" prompt) t)
             (t nil)))))
  :body (progn
          (pearl-gtd-capture)
          (pearl-gtd-process-inbox))
  :asserts (progn
             (should (test-pearl-gtd-inbox-empty-p pearl-gtd-init-base-directory))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "* Buy gift for mom"))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "Check Amazon first"))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      ":errands:")))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-workflows-user-interrupts-processing
    "User interrupts processing midway."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task to interrupt\n"))
  :mock (((symbol-function 'read-string) (lambda (&rest _) ""))  ; Mock to skip renaming
         ((symbol-function 'y-or-n-p) (lambda (&rest _) t)))  ; Simulate yes to potential prompts
  :body (condition-case err
            (pearl-gtd-process-inbox)
          (quit nil))
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    "* Task to interrupt"))
  :teardown nil)

(test-pearl-gtd-macros-define-story
    test-pearl-gtd-workflows-user-processes-mixed-destinations
    "User processes entries with mixed destinations."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Action task\n* Reference task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest _) t))
         ((symbol-function 'read-string)
          (lambda (prompt &rest _)
            (cond
             ((string-match "Rename" prompt) "")
             ((string-match "Add remarks" prompt) "")
             ((string-match "Context" prompt) "@office")
             ((string-match "Assign.*Reference" prompt) "reference")
             (t "")))))
  :body (pearl-gtd-process-inbox)
  :asserts (progn
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "actions.org" pearl-gtd-init-base-directory)
                      "* Action task"))
             (should (test-pearl-gtd-file-contains-p
                      (expand-file-name "reference.org" pearl-gtd-init-base-directory)
                      "* Reference task")))
  :teardown nil)

(provide 'test-pearl-gtd-workflows)

;;; test-pearl-gtd-workflows.el ends here
