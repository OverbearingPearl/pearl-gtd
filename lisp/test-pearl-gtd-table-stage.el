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
    "Test staging buffer creation with correct table structure."
  :setup nil
  :files (("test.org" "* First Task\n* Second Task\n"))
  :buffers ((test-stage-buf " *test-stage*"))
  :mock (((symbol-function 'display-buffer) (lambda (buffer &rest _)
                                               (setq test-stage-buf buffer))))
  :body (setq test-stage-buf (pearl-gtd-table-stage-create
                               (expand-file-name "test.org" temp-dir)
                               " *test-stage*"))
  :asserts (progn
             (should (bufferp test-stage-buf))
             (should (string= pearl-gtd-table-stage-original-file
                             (expand-file-name "test.org" temp-dir)))
             (should (null pearl-gtd-table-stage-changes))
             (with-current-buffer test-stage-buf
               (should buffer-read-only)
               (goto-char (point-min))
               (should (search-forward "| Headline" nil t))
               (should (search-forward "| Age" nil t))
               (should (search-forward "| Tags" nil t))
               (should (search-forward "| Remarks" nil t))))
  :teardown nil)

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-map-entries
    "Test mapping over entries provides correct headline and entry-ref."
  :setup (setq test-collected-entries nil)
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task A\n* Task B\n* Task C\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (progn
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline entry-ref)
               (push (cons headline entry-ref) test-collected-entries)))
            (setq test-collected-entries (nreverse test-collected-entries))))
  :asserts (progn
             (should (= (length test-collected-entries) 3))
             (should (string= (car (nth 0 test-collected-entries)) "Task A"))
             (should (string= (car (nth 1 test-collected-entries)) "Task B"))
             (should (string= (car (nth 2 test-collected-entries)) "Task C"))
             ;; Verify entry-ref structure: (buffer . row)
             (should (bufferp (car (cdr (nth 0 test-collected-entries)))))
             (should (numberp (cdr (cdr (nth 0 test-collected-entries))))))
  :teardown (progn
              (setq test-collected-entries nil)
              (when (buffer-live-p test-buf)
                (kill-buffer test-buf))))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-single
    "Test highlighting a single entry."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Single Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-highlight-entry entry-ref)))
  :asserts (with-current-buffer test-buf
             (let ((overlays (overlays-in (point-min) (point-max))))
               (should (cl-some (lambda (ov)
                                 (eq (overlay-get ov 'face)
                                     'pearl-gtd-table-stage-highlight))
                               overlays))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-highlight-move
    "Test that highlighting moves from one entry to another (only one highlight at a time)."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task One\n* Task Two\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (first-ref second-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (if (string= headline "Task One")
                   (setq first-ref ref)
                 (setq second-ref ref))))
            ;; Highlight first
            (pearl-gtd-table-stage-highlight-entry first-ref)
            ;; Move highlight to second
            (pearl-gtd-table-stage-highlight-entry second-ref)))
  :asserts (with-current-buffer test-buf
             (let ((highlight-overlays
                    (cl-remove-if-not
                     (lambda (ov)
                       (eq (overlay-get ov 'face) 'pearl-gtd-table-stage-highlight))
                     (overlays-in (point-min) (point-max)))))
               ;; Should have exactly one highlight
               (should (= (length highlight-overlays) 1))
               ;; And it should be on the second task's line
               (goto-char (overlay-start (car highlight-overlays)))
               (should (looking-at "| Task Two"))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-mark-deleted
    "Test marking an entry as deleted (trash)."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Delete Me\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-mark-deleted entry-ref)))
  :asserts (with-current-buffer test-buf
             (goto-char (point-min))
             (forward-line 2) ; To data row
             (org-table-goto-column 1) ; Move to headline column where overlay is
             (let ((overlays (overlays-at (point))))
               (should (cl-some (lambda (ov)
                                 (eq (overlay-get ov 'face)
                                     'pearl-gtd-table-stage-deleted))
                               overlays))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-mark-executed
    "Test marking an entry as executed (2min rule)."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Quick Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-mark-executed entry-ref)))
  :asserts (with-current-buffer test-buf
             (goto-char (point-min))
             (forward-line 2)
             (org-table-goto-column 1) ; Move to headline column where overlay is
             (let ((overlays (overlays-at (point))))
               (should (cl-some (lambda (ov)
                                 (eq (overlay-get ov 'face)
                                     'pearl-gtd-table-stage-executed))
                               overlays))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-add-annotation
    "Test adding annotation to an entry."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Annotated Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-add-annotation entry-ref "Test Note")))
  :asserts (with-current-buffer test-buf
             (goto-char (point-min))
             (forward-line 2)
             (should (search-forward " => Test Note" (line-end-position) t)))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-stage-change
    "Test staging a change to a cell."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-stage-change entry-ref 3 "@context")))
  :asserts (progn
             (should (= (length pearl-gtd-table-stage-changes) 1))
             (should (equal (car pearl-gtd-table-stage-changes)
                           (list 3 3 "@context"))) ; row 3, col 3, value
             (with-current-buffer test-buf
               (goto-char (point-min))
               (forward-line 2)
               (should (search-forward "@context" (line-end-position) t))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-multiple-changes
    "Test staging multiple changes accumulates correctly."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task A\n* Task B\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (ref-a ref-b)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (if (string= headline "Task A")
                   (setq ref-a ref)
                 (setq ref-b ref))))
            (pearl-gtd-table-stage-stage-change ref-a 3 "@home")
            (pearl-gtd-table-stage-stage-change ref-b 3 "@office")))
  :asserts (progn
             (should (= (length pearl-gtd-table-stage-changes) 2))
             (should (cl-some (lambda (c) (equal (nth 2 c) "@home"))
                             pearl-gtd-table-stage-changes))
             (should (cl-some (lambda (c) (equal (nth 2 c) "@office"))
                             pearl-gtd-table-stage-changes)))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-clear-changes
    "Test clearing staged changes."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-stage-change entry-ref 3 "tag")
            (pearl-gtd-table-stage-clear-changes test-buf)))
  :asserts (should (null pearl-gtd-table-stage-changes))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-reapply-marks
    "Test that marks are reapplied after table alignment (stage-change triggers reapply)."
  :setup nil
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Marked Task\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (let (entry-ref)
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (setq entry-ref ref)))
            (pearl-gtd-table-stage-mark-deleted entry-ref)
            (pearl-gtd-table-stage-stage-change entry-ref 3 "@context")))
  :asserts (with-current-buffer test-buf
             (goto-char (point-min))
             (forward-line 2)
             (org-table-goto-column 1) ; Move to headline column where overlay is
             (let ((overlays (overlays-at (point))))
               (should (cl-some (lambda (ov)
                                 (eq (overlay-get ov 'face)
                                     'pearl-gtd-table-stage-deleted))
                               overlays))
               (should (search-forward "@context" (line-end-position) t))))
  :teardown (when (buffer-live-p test-buf)
              (kill-buffer test-buf)))

(test-pearl-gtd-macros-define-test test-pearl-gtd-table-stage-multi-entry-processing
    "Test processing multiple entries sequentially with different operations."
  :setup (setq test-operations-log nil)
  :mock (((symbol-function 'display-buffer) (lambda (&rest _) nil)))
  :files (("test.org" "* Task One\n* Task Two\n* Task Three\n"))
  :buffers ((test-buf " *test-stage*"))
  :body (progn
          (setq test-buf (pearl-gtd-table-stage-create (expand-file-name "test.org" temp-dir)))
          (with-current-buffer test-buf
            (pearl-gtd-table-stage-map-entries
             test-buf
             (lambda (headline ref)
               (cond
                ((string= headline "Task One")
                 (pearl-gtd-table-stage-mark-deleted ref)
                 (push "one-deleted" test-operations-log))
                ((string= headline "Task Two")
                 (pearl-gtd-table-stage-mark-executed ref)
                 (push "two-executed" test-operations-log))
                ((string= headline "Task Three")
                 (pearl-gtd-table-stage-stage-change ref 3 "@context")
                 (push "three-tagged" test-operations-log)))))))
  :asserts (progn
             (should (= (length test-operations-log) 3))
             (should (member "one-deleted" test-operations-log))
             (should (member "two-executed" test-operations-log))
             (should (member "three-tagged" test-operations-log))
             ;; Verify visual states in buffer
             (with-current-buffer test-buf
               (goto-char (point-min))
               (forward-line 2) ; Task One
               (org-table-goto-column 1)
               (let ((overlays (overlays-at (point))))
                 (should (cl-some (lambda (ov)
                                   (eq (overlay-get ov 'face)
                                       'pearl-gtd-table-stage-deleted))
                                 overlays)))
               (forward-line 1) ; Task Two
               (org-table-goto-column 1)
               (let ((overlays (overlays-at (point))))
                 (should (cl-some (lambda (ov)
                                   (eq (overlay-get ov 'face)
                                       'pearl-gtd-table-stage-executed))
                                 overlays)))
               (forward-line 1) ; Task Three
               (should (search-forward "@context" (line-end-position) t))))
  :teardown (progn
              (setq test-operations-log nil)
              (when (buffer-live-p test-buf)
                (kill-buffer test-buf))))

(provide 'test-pearl-gtd-table-stage)

;;; test-pearl-gtd-table-stage.el ends here
