;;; test-pearl-gtd-table-stage.el --- Tests for pearl-gtd-table-stage  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file contains tests for pearl-gtd-table-stage.

;;; Code:

(require 'ert)
(require 'pearl-gtd-table-stage)
(require 'test-pearl-gtd-macros)  ; Require the macros file
(require 'cl-lib)

;; Tests for pearl-gtd-table-stage
(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-create
    "Test creating the staging buffer."
  :setup (progn
           (setq test-file (expand-file-name "test.org" temp-dir))
           (with-temp-file test-file
             (insert "* Test Table\n| A | B |\n| 1 | 2 |")))
  :files ((test.org "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (pearl-gtd-table-stage-create test-file)
  :asserts (should (get-buffer pearl-gtd-table-stage-buffer-name))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-change
    "Test staging a change."
  :setup (progn
           (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
  :files ((test.org "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (with-current-buffer pearl-gtd-table-stage-buffer-name
          (pearl-gtd-table-stage-stage-change 2 2 "3"))
  :asserts (should (member '(2 2 "3") pearl-gtd-table-stage-changes))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-apply-changes
    "Test applying changes."
  :setup (progn
           (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
           (with-current-buffer pearl-gtd-table-stage-buffer-name
             (pearl-gtd-table-stage-stage-change 2 2 "3")))
  :files ((test.org "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (pearl-gtd-table-stage-apply-changes)
  :asserts (with-temp-buffer
              (insert-file-contents (expand-file-name "test.org" temp-dir))
              (goto-char (point-min))
              (re-search-forward "| 3 |" nil t)
              (should (match-string 0)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(provide 'test-pearl-gtd-table-stage)

;;; test-pearl-gtd-table-stage.el ends here
