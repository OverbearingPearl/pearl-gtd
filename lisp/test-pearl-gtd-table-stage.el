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
(require 'test-pearl-gtd-macros)
(require 'cl-lib)

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-create-buffer
    "Test staging buffer creation and basic properties."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Heading\n| A | B |\n| 1 | 2 |\n"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (progn
             (should (get-buffer pearl-gtd-table-stage-buffer-name))
             (should (string= pearl-gtd-table-stage-original-file 
                             (expand-file-name "test.org" temp-dir)))
             (should (null pearl-gtd-table-stage-changes))
             (with-current-buffer pearl-gtd-table-stage-buffer-name
               (should buffer-read-only)))
  :teardown (when (get-buffer pearl-gtd-table-stage-buffer-name)
              (kill-buffer pearl-gtd-table-stage-buffer-name)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-display-table
    "Test table content display and alignment."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "| Column1 | Column2 |\n| Value1 | Value2 |\n"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (goto-char (point-min))
             (should (search-forward "| Column1 | Column2 |" nil t))
             (should (search-forward "| Value1 | Value2 |" nil t)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-entry
    "Test visual highlight of entries."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* First Heading\nContent line 1\n* Second Heading\nContent line 2\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (with-current-buffer pearl-gtd-table-stage-buffer-name
            (goto-char (point-min))
            (pearl-gtd-table-stage-highlight-current-entry (search-forward "* First Heading"))
            (pearl-gtd-table-stage-highlight-current-entry (search-forward "* Second Heading"))))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (let ((overlays-first (overlays-at (save-excursion 
                                                  (goto-char (point-min))
                                                  (search-forward "* First Heading")
                                                  (line-beginning-position))))
                   (overlays-second (overlays-at (save-excursion 
                                                   (goto-char (point-min))
                                                   (search-forward "* Second Heading")
                                                   (line-beginning-position)))))
               (should (cl-some (lambda (ov) (equal (overlay-get ov 'face) '(:background "yellow"))) 
                               overlays-first))
               (should (cl-some (lambda (ov) (equal (overlay-get ov 'face) '(:background "yellow"))) 
                               overlays-second))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-add-annotation
    "Test visual annotation addition."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Test Heading\nContent line\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (with-current-buffer pearl-gtd-table-stage-buffer-name
            (pearl-gtd-table-stage-add-annotation (point-min) "Test Annotation")))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (goto-char (point-min))
             (should (search-forward " => Test Annotation" nil t)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-single-change
    "Test staging a single change."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "| A | B |\n| 1 | 2 |\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change 2 2 "3"))
  :asserts (progn
             (should (equal pearl-gtd-table-stage-changes '((2 2 "3"))))
             (with-current-buffer pearl-gtd-table-stage-buffer-name
               (goto-char (point-min))
               (org-table-goto-line 2)
               (org-table-goto-column 2)
               (let ((overlays (overlays-at (point))))
                 (should (cl-some (lambda (ov) (equal (overlay-get ov 'face) '(:background "yellow")))
                                 overlays)))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-multiple-changes
    "Test staging multiple changes accumulates correctly."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "| A | B | C |\n| 1 | 2 | 3 |\n| 4 | 5 | 6 |\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change 2 2 "X")
          (pearl-gtd-table-stage-stage-change 2 3 "Y")
          (pearl-gtd-table-stage-stage-change 3 1 "Z"))
  :asserts (progn
             (should (= (length pearl-gtd-table-stage-changes) 3))
             (should (member '(2 2 "X") pearl-gtd-table-stage-changes))
             (should (member '(2 3 "Y") pearl-gtd-table-stage-changes))
             (should (member '(3 1 "Z") pearl-gtd-table-stage-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-apply-changes-to-file
    "Test applying staged changes to original file."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "| A | B |\n| 1 | 2 |\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change 2 2 "9")
          (pearl-gtd-table-stage-apply-changes))
  :asserts (let ((file-content (with-temp-buffer
                                 (insert-file-contents (expand-file-name "test.org" temp-dir))
                                 (buffer-string))))
             (should (string-match-p "| 9 |" file-content))
             (should-not (string-match-p "| 2 |" file-content))
             (should (null pearl-gtd-table-stage-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-keymap-bindings
    "Test that keymap bindings are set correctly."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "| A | B |\n"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (should (eq (lookup-key (current-local-map) (kbd "C-c C-s"))
                        'pearl-gtd-table-stage-stage-change))
             (should (eq (lookup-key (current-local-map) (kbd "C-c C-a"))
                        'pearl-gtd-table-stage-apply-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(provide 'test-pearl-gtd-table-stage)

;;; test-pearl-gtd-table-stage.el ends here
