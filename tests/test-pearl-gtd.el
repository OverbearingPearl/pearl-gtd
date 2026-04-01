;;; tests/test-pearl-gtd.el --- Tests for pearl-gtd  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file contains tests for pearl-gtd.

;;; Code:

(require 'ert)
(require 'pearl-gtd)
(require 'test-pearl-gtd-macros)  ; Require the macros file
(require 'cl-lib)

;; Tests for pearl-gtd initialization
(test-pearl-gtd-macros-define-test test-pearl-gtd-initialize
    "Test initializing the Pearl-GTD system."
  :setup nil
  :files nil
  :body (pearl-gtd-initialize)
  :asserts (let ((dir pearl-gtd-base-directory))
             (should (file-directory-p dir))
             (should (file-exists-p (expand-file-name "inbox.org" dir)))
             (should (file-exists-p (expand-file-name "reference.org" dir)))
             (should (file-exists-p (expand-file-name "someday.org" dir)))
             (should (file-exists-p (expand-file-name "actions.org" dir))))
  :teardown (dolist (file '("inbox.org" "reference.org" "someday.org" "actions.org"))
              (delete-file (expand-file-name file pearl-gtd-base-directory)))
             (delete-directory pearl-gtd-base-directory))

(provide 'test-pearl-gtd)

;;; tests/test-pearl-gtd.el ends here
