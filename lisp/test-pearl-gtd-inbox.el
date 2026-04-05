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
  :teardown (delete-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))

;; Test processing path: actionable and can be done in 2 minutes
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-immediate
    "Test processing path: actionable and can be done in 2 minutes."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Quick task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) t))
         ((symbol-function 'read-string) (lambda (&rest args) "Quick task")))
  :body (pearl-gtd-inbox-process)
  :asserts (should-not
             (with-current-buffer
                 (find-file-noselect (expand-file-name "inbox.org" pearl-gtd-init-base-directory))
               (search-forward "* Quick task" nil t)))
           (should (file-exists-p (expand-file-name "actions.org" pearl-gtd-init-base-directory)))
  :teardown (dolist (file '("inbox.org" "actions.org"))
              (delete-file (expand-file-name file pearl-gtd-init-base-directory))))

;; Test processing path: actionable with context
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-context
    "Test processing path: actionable with context."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task with context\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "actionable" (car args)) t)
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "context" (car args)) t)
              (t nil)))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (should (search-forward " => Added :CONTEXT:" nil t)))))
  :teardown (kill-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))

;; Test processing path: actionable with scheduled date
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-scheduled
    "Test processing path: actionable with scheduled date."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task with schedule\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "actionable" (car args)) t)
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "scheduled" (car args)) t)
              (t nil)))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (should (search-forward " => Added SCHEDULED:" nil t)))))
  :teardown (kill-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))

;; Test processing path: actionable with delegation
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-delegated
    "Test processing path: actionable with delegation."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Task delegated\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "actionable" (car args)) t)
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "delegated" (car args)) t)
              (t nil)))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (should (search-forward " => Added :DELEGATED:" nil t)))))
  :teardown (kill-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))

;; Test processing path: actionable as a project
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-actionable-with-project
    "Test processing path: actionable as a project."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Project task\n"))
  :mock (((symbol-function 'y-or-n-p)
          (lambda (&rest args)
            (cond
              ((string-match "actionable" (car args)) t)
              ((string-match "2 minutes" (car args)) nil)
              ((string-match "project" (car args)) t)
              (t nil)))))
  :body (pearl-gtd-inbox-process)
  :asserts (let ((stage-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))
             (when stage-buffer
               (with-current-buffer stage-buffer
                 (should (search-forward " => Added :PROJECT:" nil t)))))
  :teardown (kill-buffer (get-buffer pearl-gtd-inbox-stage-buffer-name)))

;; Test processing path: non-actionable to reference
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-reference
    "Test processing path: non-actionable to reference."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Non-actionable task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string) (lambda (&rest args) "reference")))
  :body (pearl-gtd-inbox-process)
  :asserts (should (file-exists-p (expand-file-name "reference.org" pearl-gtd-init-base-directory)))
  :teardown (delete-file (expand-file-name "reference.org" pearl-gtd-init-base-directory)))

;; Test processing path: non-actionable to someday
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-someday
    "Test processing path: non-actionable to someday."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Someday task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string) (lambda (&rest args) "someday")))
  :body (pearl-gtd-inbox-process)
  :asserts (should (file-exists-p (expand-file-name "someday.org" pearl-gtd-init-base-directory)))
  :teardown (delete-file (expand-file-name "someday.org" pearl-gtd-init-base-directory)))

;; Test processing path: non-actionable to trash
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process-non-actionable-to-trash
    "Test processing path: non-actionable to trash."
  :setup (pearl-gtd-init-initialize)
  :files (("inbox.org" "* Trash task\n"))
  :mock (((symbol-function 'y-or-n-p) (lambda (&rest args) nil))
         ((symbol-function 'read-string) (lambda (&rest args) "trash")))
  :body (pearl-gtd-inbox-process)
  :asserts (should-not (file-exists-p (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))
  :teardown (delete-file (expand-file-name "inbox.org" pearl-gtd-init-base-directory)))

(provide 'test-pearl-gtd-inbox)

;;; test-pearl-gtd-inbox.el ends here
