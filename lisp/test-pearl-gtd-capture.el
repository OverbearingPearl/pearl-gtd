;;; test-pearl-gtd-capture.el --- User stories: Capture phase  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; User stories for capturing items into inbox.

;;; Code:

(require 'ert)
(require 'pearl-gtd)
(require 'test-pearl-gtd)

(test-pearl-gtd-define-story
    test-pearl-gtd-capture-user-captures-simple-idea-to-inbox
    "User runs M-x pearl-gtd-capture and inputs 'Buy milk'."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest _) "Buy milk")))
  :body (pearl-gtd-capture)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    "* Buy milk"))
  :teardown nil)

(test-pearl-gtd-define-story
    test-pearl-gtd-capture-user-captures-idea-with-timestamp
    "Captured items automatically get CREATED timestamp."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest _) "Task with time")))
  :body (pearl-gtd-capture)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    ":CREATED:"))
  :teardown nil)

(test-pearl-gtd-define-story
    test-pearl-gtd-capture-user-captures-empty-string
    "User attempts to capture an empty string."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest _) "")))
  :body (pearl-gtd-capture)
  :asserts (should-not (test-pearl-gtd-file-contains-p
                        (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                        "* "))
  :teardown nil)

(test-pearl-gtd-define-story
    test-pearl-gtd-capture-user-captures-special-chars
    "User captures task with special characters."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest _) "Fix [urgent] bug")))
  :body (pearl-gtd-capture)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    "* Fix [urgent] bug"))
  :teardown nil)

(test-pearl-gtd-define-story
    test-pearl-gtd-capture-user-captures-very-long-title
    "User captures a very long title."
  :setup (pearl-gtd-init-initialize)
  :files nil
  :mock (((symbol-function 'read-string) (lambda (&rest _) "This is a very long title that exceeds normal length for testing purposes")))
  :body (pearl-gtd-capture)
  :asserts (should (test-pearl-gtd-file-contains-p
                    (expand-file-name "inbox.org" pearl-gtd-init-base-directory)
                    "* This is a very long title that exceeds normal length for testing purposes"))
  :teardown nil)

(provide 'test-pearl-gtd-capture)

;;; test-pearl-gtd-capture.el ends here
