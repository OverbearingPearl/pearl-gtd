;;; test-pearl-gtd-macros.el --- Shared macros for user story tests  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file contains macros for defining user story tests with consistent structure.

;;; Code:

(require 'cl-lib)

(defmacro test-pearl-gtd-macros-define-story (name docstring &rest args)
  "Define a user story test named NAME with DOCSTRING.
ARGS is a plist with keys:
:setup - Form to run before test
:files - List of (filename content) to create
:mock - List of cl-letf bindings for user input simulation
:body - The test body form
:asserts - Assertion forms
:teardown - Cleanup form"
  (declare (indent defun))
  (let ((setup (plist-get args :setup))
        (files (plist-get args :files))
        (mock (plist-get args :mock))
        (body (plist-get args :body))
        (asserts (plist-get args :asserts))
        (teardown (plist-get args :teardown)))
    `(ert-deftest ,name ()
       ,docstring
       (let* ((temp-dir (make-temp-file "test-pearl-gtd-" t))
              (pearl-gtd-init-base-directory temp-dir))
         (unwind-protect
             (progn
               ,setup
               ;; Create test files
               (dolist (file-spec ',files)
                 (let ((file (car file-spec))
                       (content (cadr file-spec)))
                   (with-temp-file (expand-file-name file temp-dir)
                     (insert content))))
               ;; Run test with mocks
               (cl-letf ,mock
                 ,body
                 ,asserts))
           ;; Teardown
           (ignore-errors ,teardown)
           ;; Cleanup files
           (dolist (file (directory-files temp-dir t "\\.org$"))
             (when (file-exists-p file)
               (delete-file file)))
           (delete-directory temp-dir))))))

(provide 'test-pearl-gtd-macros)

;;; test-pearl-gtd-macros.el ends here
