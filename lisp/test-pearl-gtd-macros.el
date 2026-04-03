;;; test-pearl-gtd-macros.el --- Common macros for pearl-gtd tests  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This file contains common macros for pearl-gtd tests.

;;; Code:

(require 'cl-lib)

(defmacro test-pearl-gtd-macros-define-test (name docstring &rest args)
  "Define an ERT test for pearl-gtd with structured setup.
NAME is the test name symbol.
DOCSTRING is the test description.
ARGS is a plist with keys: :setup, :files, :mock, :body, :asserts, :teardown.
If :SETUP, :BODY, :ASSERTS, or :TEARDOWN contain multiple forms, wrap them in (progn ...).
:MOCK should be a list of bindings suitable for `cl-letf', which will wrap :BODY and :ASSERTS.
:FILES is expected to be a list in its specific format and is not wrapped."
  (declare (indent defun))
  (let ((setup (plist-get args :setup))
        (files (plist-get args :files))
        (mock (plist-get args :mock))
        (body (plist-get args :body))
        (asserts (plist-get args :asserts))
        (teardown (plist-get args :teardown)))
    `(ert-deftest ,name ()
       ,docstring
       (save-window-excursion
         (save-excursion
           (let* ((temp-dir (make-temp-file "test-pearl-gtd-" t))
                  (pearl-gtd-base-directory temp-dir))
             ,setup
             (dolist (file-spec ',files)
               (let ((file (car file-spec))
                     (content (cadr file-spec)))
                 (with-temp-file (expand-file-name file temp-dir)
                   (insert content))))
             (unwind-protect
                 (progn
                   (dolist (file (directory-files temp-dir t "\\.org$"))
                     (when (get-file-buffer file)
                       (with-current-buffer (get-file-buffer file)
                         (auto-revert-mode 1))))
                   (cl-letf ,mock
                     ,body
                     ,asserts))
               ,teardown)))))))

(provide 'test-pearl-gtd-macros)

;;; test-pearl-gtd-macros.el ends here
