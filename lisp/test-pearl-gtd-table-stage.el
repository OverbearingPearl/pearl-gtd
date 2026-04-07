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
  :files (("test.org" "* Heading\n* Another Heading\n"))
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
  :files (("test.org" "* Column1\n* Value1\n"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (goto-char (point-min))
             (should (search-forward "| Headline" nil t))
             (should (search-forward "| Tags" nil t))
             (should (search-forward "| State" nil t))
             (should (search-forward "| Age" nil t)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-entry
    "Test visual highlight of entries."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* First Heading\n* Second Heading\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (with-current-buffer pearl-gtd-table-stage-buffer-name
            (pearl-gtd-table-stage-highlight-entry (current-buffer) 3)))  ; Row 3
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (let ((overlays (overlays-at (save-excursion 
                                            (goto-char (point-min))
                                            (forward-line 2)  ; To row 3
                                            (line-beginning-position)))))
               (should (cl-some (lambda (ov) (equal (overlay-get ov 'face) '(:background "yellow"))) 
                               overlays))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-add-annotation
    "Test visual annotation addition."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Test Heading\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (with-current-buffer pearl-gtd-table-stage-buffer-name
            (pearl-gtd-table-stage-add-annotation (current-buffer) 3 "Test Annotation")))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (goto-char (point-min))
             (forward-line 2)  ; To row 3
             (should (search-forward " => Test Annotation" (line-end-position) t)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-single-change
    "Test staging a single change."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Test\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change (get-buffer pearl-gtd-table-stage-buffer-name) 3 2 "3"))  ; Row 3, Col 2
  :asserts (progn
             (should (equal pearl-gtd-table-stage-changes '((3 2 "3"))))
             (with-current-buffer pearl-gtd-table-stage-buffer-name
               (goto-char (point-min))
               (org-table-goto-line 3)
               (org-table-goto-column 2)
               (let ((overlays (overlays-at (point))))
                 (should (cl-some (lambda (ov) (equal (overlay-get ov 'face) '(:background "yellow")))
                                 overlays)))))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-multiple-changes
    "Test staging multiple changes accumulates correctly."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* A\n* B\n* C\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change (get-buffer pearl-gtd-table-stage-buffer-name) 3 2 "X")
          (pearl-gtd-table-stage-stage-change (get-buffer pearl-gtd-table-stage-buffer-name) 4 3 "Y")
          (pearl-gtd-table-stage-stage-change (get-buffer pearl-gtd-table-stage-buffer-name) 5 1 "Z"))
  :asserts (progn
             (should (= (length pearl-gtd-table-stage-changes) 3))
             (should (member '(3 2 "X") pearl-gtd-table-stage-changes))
             (should (member '(4 3 "Y") pearl-gtd-table-stage-changes))
             (should (member '(5 1 "Z") pearl-gtd-table-stage-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-clear-changes
    "Test clearing staged changes."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Test\n"))
  :body (progn
          (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
          (pearl-gtd-table-stage-stage-change (get-buffer pearl-gtd-table-stage-buffer-name) 3 2 "9")
          (pearl-gtd-table-stage-clear-changes (get-buffer pearl-gtd-table-stage-buffer-name)))
  :asserts (progn
             (should (null pearl-gtd-table-stage-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-keymap-bindings
    "Test that keymap bindings are set correctly."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* A\n"))
  :body (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir))
  :asserts (with-current-buffer pearl-gtd-table-stage-buffer-name
             (should (eq (lookup-key (current-local-map) (kbd "C-c C-s"))
                        'pearl-gtd-table-stage-stage-change))
             (should (eq (lookup-key (current-local-map) (kbd "C-c C-a"))
                        'pearl-gtd-table-stage-clear-changes)))
  :teardown (kill-buffer pearl-gtd-table-stage-buffer-name))

(provide 'test-pearl-gtd-table-stage)

;;; test-pearl-gtd-table-stage.el ends here
