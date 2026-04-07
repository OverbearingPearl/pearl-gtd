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
ARGS is a plist with keys: :setup, :files, :buffers, :mock, :body, :asserts, :teardown.
:FILES is a list of (filename content) pairs to create.
:BUFFERS is a list of (varname buffer-name) or (varname buffer-name initial-content) to bind.
:MOCK is a list of bindings for `cl-letf'."
  (declare (indent defun))
  (let ((setup (plist-get args :setup))
        (files (plist-get args :files))
        (buffers (plist-get args :buffers))
        (mock (plist-get args :mock))
        (body (plist-get args :body))
        (asserts (plist-get args :asserts))
        (teardown (plist-get args :teardown)))
    ;; Generate buffer variable bindings and cleanup code
    (let ((buffer-bindings
           (mapcar (lambda (buf-spec)
                     (let ((var (car buf-spec))
                           (name (cadr buf-spec))
                           (content (caddr buf-spec)))
                       `(,var (progn
                                (when (get-buffer ,name)
                                  (kill-buffer ,name))
                                (with-current-buffer (get-buffer-create ,name)
                                  (erase-buffer)
                                  ,@(when content `((insert ,content)))
                                  (current-buffer))))))
                   buffers))
          (buffer-cleanup
           (mapcar (lambda (buf-spec)
                     `(when (buffer-live-p ,(car buf-spec))
                        (kill-buffer ,(car buf-spec))))
                   buffers)))
      `(ert-deftest ,name ()
         ,docstring
         (save-window-excursion
           (save-excursion
             (let* ((temp-dir (make-temp-file "test-pearl-gtd-" t))
                    (pearl-gtd-init-base-directory temp-dir)
                    ,@buffer-bindings)
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
                 ,teardown
                 ,@buffer-cleanup))))))))

(provide 'test-pearl-gtd-macros)

;;; test-pearl-gtd-macros.el ends here
