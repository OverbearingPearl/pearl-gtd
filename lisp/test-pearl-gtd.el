;;; test-pearl-gtd.el --- Test infrastructure and entry point  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file provides shared infrastructure for Pearl-GTD user story tests.
;; It contains assertion helpers and test runners.

;;; Code:

(require 'ert)

(defun test-pearl-gtd-file-contains-p (file pattern)
  "Assert that FILE contains PATTERN."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (search-forward pattern nil t)))

(defun test-pearl-gtd-file-lacks-p (file pattern)
  "Assert that FILE does not contain PATTERN."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (not (search-forward pattern nil t))))

(defun test-pearl-gtd-inbox-empty-p (base-dir)
  "Check if inbox is visually empty (missing or zero size)."
  (let ((inbox (expand-file-name "inbox.org" base-dir)))
    (or (not (file-exists-p inbox))
        (= 0 (file-attribute-size (file-attributes inbox))))))

(defun test-pearl-gtd-task-exists-p (file title)
  "Check if task TITLE exists in FILE."
  (test-pearl-gtd-file-contains-p file (format "* %s" title)))

(provide 'test-pearl-gtd)

;;; test-pearl-gtd.el ends here
