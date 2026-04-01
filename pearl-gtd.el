;;; pearl-gtd.el --- Complete GTD implementation for org-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.4") (pearl-gtd-inbox "0.1.0"))
;; Keywords: outlines, tools, convenience, productivity, gtd, org
;; URL: https://github.com/OverbearingPearl/pearl-gtd

;;; Commentary:

;; This package provides a complete GTD implementation for org-mode,
;; including six horizon levels: Purpose, Vision, Goals, Areas,
;; Projects, and Actions.

;;; Code:

;; Capture the directory when the file is loaded
(defvar pearl-gtd-directory (and load-file-name (file-name-directory load-file-name))
  "Directory of the pearl-gtd.el file.")

(dolist (dir '("infra" "modules" "tests"))
  (add-to-list 'load-path (expand-file-name dir pearl-gtd-directory)))

(defvar pearl-gtd-base-directory (expand-file-name "~/.pearl-gtd/")
  "Base directory for Pearl-GTD.")

(require 'pearl-gtd-inbox)  ; Require the inbox module

(defun pearl-gtd-initialize ()
  "Initialize the Pearl-GTD system by creating the base directory and necessary files."
  (interactive)
  (let ((dir pearl-gtd-base-directory))
    (unless (file-directory-p dir)
      (make-directory dir))
    ;; Create necessary files
    (dolist (file '("inbox.org" "reference.org" "someday.org" "actions.org"))
      (let ((file-path (expand-file-name file dir)))
        (unless (file-exists-p file-path)
          (with-temp-file file-path
            (insert ";; " file "\n")))))  ; Simple initialization
    (message "Pearl-GTD initialized in %s" dir)))

(defun pearl-gtd-process-inbox ()
  "Process the inbox."
  (interactive)
  (pearl-gtd-inbox-process))

(defun pearl-gtd-run-tests ()
  "Run all Pearl-GTD unit tests."
  (interactive)
  (require 'ert)
  (pearl-gtd-reload-modules)
  (let* ((tests-dir (expand-file-name "tests" pearl-gtd-directory))
         (el-files (directory-files tests-dir nil "\\.el$")))
    (dolist (file el-files)
      (when (string-match "^test-.*\\.el$" file)
        (let ((feature (intern (file-name-base file))))
          (require feature))))
    (ert t)))

(defun pearl-gtd-reload-modules ()
  "Reload Pearl-GTD modules for updated code."
  (interactive)
  (let* ((dirs '("infra" "modules" "tests"))
         (load-path-dirs
          (mapcar (lambda (dir)
                    (expand-file-name dir pearl-gtd-directory))
                  dirs))
         (features '()))
    (dolist (dir load-path-dirs)
      (dolist (file (directory-files dir nil "\\.el$"))
        (when (string-match "^[^.]+\\.el$" file)
          (let ((feature (intern (file-name-base file))))
            (push feature features)))))
    (dolist (feature features)
      (when (featurep feature)
        (condition-case nil
            (unload-feature feature)
          (error nil))))  ; Ignore errors when unloading
    (dolist (feature features)
      (require feature))
    (message "Modules reloaded.")))

(provide 'pearl-gtd)

;;; pearl-gtd.el ends here
