#!/usr/bin/env sh
":"; exec emacs --quick --script "$0" -- "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-
;;; bin/org-export

;; Exports blocks from org files. Debug/info messages are directed to stderr and
;; can be ignored.
;;
;;   -a/--all
;;     Export all blocks by default (unless it has :exports none set or a
;;     :noexport: tag)
;;   -t/--tag TAG
;;      --and TAG
;;      --or TAG
;;     Only include blocks in trees that have these tags. Combine multiple --and
;;     and --or's, or just use --tag (implicit --and).
;;   -p/--print
;;     Prints exported code to stdout instead of to files
;;
;; Usage: org-export some-file.org another.org
;; Examples:
;;   org-export -l sh modules/some/module/README.org > install_module.sh
;;   org-export -l sh modules/lang/go/README.org | sh
;;   org-export --and tagA --and tagB my/literate/config.org

(require 'cl-lib)
(require 'ox)
(require 'ox-html)
(load-file (concat (file-name-directory (or load-file-name buffer-file-name)) "org-export-functions.el"))

(setq debug-on-error t)

(defun usage ()
  (with-temp-buffer
    (insert (format "%s %s [OPTIONS] [TARGETS...]\n"
                    "[1mUsage:[0m"
                    (file-name-nondirectory load-file-name))
            "\n"
            "A command line interface for tangling org-mode files. TARGETS can be\n"
            "files or folders (which are searched for org files recursively).\n"
            "\n"
            "This is useful for literate configs that rely on command line\n"
            "workflows to build it.\n"
            "\n"
            "[1mExample:[0m\n"
            "  org-export some-file.org\n"
            "  org-export literate/config/\n"
            "  org-export -p -l sh scripts.org > do_something.sh\n"
            "  org-export -p -l python -t tagA -t tagB file.org | python\n"
            "\n"
            "[1mOptions:[0m\n"
            "  -a --all\t\tExport all blocks by default\n"
            "  -p --print\t\tPrint exported output to stdout than to files\n"
            "  -t --tag TAG\n"
            "     --and TAG\n"
            "     --or TAG\n"
            "    Lets you export org blocks by tag. You may have more than one\n"
            "    of these options.\n")
    (princ (buffer-string))))

(defun *org-babel-export (fn &rest args)
  "Don't write exported blocks to files, print them to stdout."
  (cl-letf (((symbol-function 'write-region)
             (lambda (start end filename &optional append visit lockname mustbenew)
               (princ (buffer-string)))))
    (apply fn args)))

(defvar all-blocks nil)
(defvar and-tags nil)
(defvar or-tags nil)
(let (srcs and-tags or-tags)
  (pop argv)
  (while argv
    (let ((arg (pop argv)))
      (pcase arg
        ((or "-h" "--help")
         (usage)
         (error ""))
        ((or "-a" "--all")
         (setq all-blocks t))
        ((or "-p" "--print")
         (advice-add #'org-html-export-to-html :around #'*org-babel-export))
        ((or "-t" "--tag" "--and")
         (push (pop argv) and-tags))
        ("--or"
         (push (pop argv) or-tags))
        ((guard (file-directory-p arg))
         (setq srcs
               (append (directory-files-recursively arg "\\.org$")
                       srcs)))
        ((guard (file-exists-p arg))
         (push arg srcs))
        (_ (error "Unknown option or file: %s" arg)))))

  (dolist (file srcs)
                (message (format "\n\nNow exporting %s:\n" file))
    (let ((backup (make-temp-file (file-name-base file) nil ".backup.org")))
      (unwind-protect
          ;; Prevent slow hooks from interfering
          (let (org-mode-hook org-confirm-babel-evaluate)
               (with-current-buffer (find-file-noselect file)
               (org-html-export-to-html)))
        (ignore-errors (delete-file backup)))))
  (kill-emacs 0))
