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
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (should (get-buffer pearl-gtd-table-stage-buffer-name))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

;; Test for pearl-gtd-table-stage-highlight-current-entry
(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-current-entry
    "Test highlighting an entry at specific positions."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Heading 1\nContent 1\n* Test Heading 2\nContent 2"))
  :body (with-current-buffer (get-buffer-create pearl-gtd-table-stage-buffer-name)
          (insert "* Test Heading 1\nContent 1\n* Test Heading 2\nContent 2")
          (pearl-gtd-table-stage-highlight-current-entry (search-forward "* Test Heading 1"))
          (pearl-gtd-table-stage-highlight-current-entry (search-forward "* Test Heading 2")))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (should (overlay-p (car (overlays-at (save-excursion (search-forward "* Test Heading 1") (line-beginning-position))))))
             (should (overlay-p (car (overlays-at (save-excursion (search-forward "* Test Heading 2") (line-beginning-position))))))
             (should (equal (overlay-get (car (overlays-at (save-excursion (search-forward "* Test Heading 1") (line-beginning-position)))) 'face) '(:background "yellow"))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-current-entry-isolated
    "Test highlighting an entry in isolation."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files nil
  :body (with-current-buffer (get-buffer-create pearl-gtd-table-stage-buffer-name)
          (insert "* Test Heading\n")
          (pearl-gtd-table-stage-highlight-current-entry (point-min)))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (should (overlay-p (car (overlays-at (point-min)))))
             (should (equal (overlay-get (car (overlays-at (point-min))) 'face) '(:background "yellow"))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-add-annotation-highlight
    "Test adding annotation with highlight."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Heading\nContent"))
  :body (with-current-buffer pearl-gtd-table-stage-buffer-name
          (insert "* Test Heading\nContent")
          (pearl-gtd-table-stage-add-annotation (point-min) "Test Annotation"))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (should (search-forward " => Test Annotation" nil t)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-change
    "Test staging a change with visual feedback and no overlay conflict."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (with-current-buffer pearl-gtd-table-stage-buffer-name
          (pearl-gtd-table-stage-stage-change 2 2 "3"))
  :asserts (should (member '(2 2 "3") pearl-gtd-table-stage-changes))
            (should (overlay-p (car (overlays-at (point)))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-apply-changes
    "Test applying changes."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Table\n| A | B |\n| 1 | 2 |"))
  :body (pearl-gtd-table-stage-apply-changes)
  :asserts (with-temp-buffer
              (insert-file-contents (expand-file-name "test.org" temp-dir))
              (goto-char (point-min))
              (re-search-forward "| 3 |" nil t)
              (should (match-string 0)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-add-annotation
    "Test adding annotation."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest args) nil)))
  :files (("test.org" "* Test Heading\nContent"))
  :body (with-current-buffer pearl-gtd-table-stage-buffer-name
          (insert "* Test Heading\nContent")
          (pearl-gtd-table-stage-add-annotation (point-min) "Test Annotation")
          (goto-char (point-min))
          (search-forward " => Test Annotation"))
  :asserts (should (search-forward " => Test Annotation" nil t))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(provide 'test-pearl-gtd-table-stage)

;;; test-pearl-gtd-table-stage.el ends here
