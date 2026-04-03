;;; tests/pearl-gtd-inbox.el --- Tests for pearl-gtd-inbox  -*- lexical-binding: t; -*-

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
(require 'modules-pearl-gtd-inbox)
(require 'test-pearl-gtd-macros)  ; Require the macros file
(require 'cl-lib)

;; Tests for pearl-gtd-capture
(test-pearl-gtd-macros-define-test test-pearl-gtd-capture
    "Test capturing a new item to the inbox with timestamp."
  :setup (require 'pearl-gtd)  ; Ensure pearl-gtd is loaded for initialize
         (pearl-gtd-initialize)
  :files nil
  :body (with-mock
          (mock (read-string "Enter item to capture: ") => "Test item")
          (pearl-gtd-inbox-capture))
  :asserts (let ((inbox-file (expand-file-name "inbox.org" pearl-gtd-base-directory)))
             (with-temp-buffer
               (insert-file-contents inbox-file)
               (goto-char (point-max))
               (search-backward "* Test item" nil t)
               (forward-line 1)  ; Check for properties
               (should (search-forward ":CREATED:" nil t))))
  :teardown (dolist (file '("inbox.org" "reference.org" "someday.org" "actions.org"))
              (delete-file (expand-file-name file pearl-gtd-base-directory)))
             (delete-directory pearl-gtd-base-directory))

;; Tests for pearl-gtd-inbox-process
(test-pearl-gtd-macros-define-test test-pearl-gtd-inbox-process
    "Test processing the inbox."
  :setup (require 'pearl-gtd)  ; Ensure pearl-gtd is loaded
         (pearl-gtd-initialize)
  :files nil
  :body (pearl-gtd-inbox-process)
  :asserts (should (get-buffer pearl-gtd-table-stage-buffer-name))
  :teardown (when (get-buffer pearl-gtd-table-stage-buffer-name)
              (kill-buffer pearl-gtd-table-stage-buffer-name))
            (dolist (file '("inbox.org" "reference.org" "someday.org" "actions.org"))
              (delete-file (expand-file-name file pearl-gtd-base-directory)))
            (delete-directory pearl-gtd-base-directory))

(provide 'test-pearl-gtd-inbox)

;;; tests/pearl-gtd-inbox.el ends here
