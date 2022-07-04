(mapc (lambda (file) (load-file (concat (file-name-directory (or load-file-name buffer-file-name)) (concat file ".el")))) '(
    "uuidgen"
    "a"
    "dash"
    "s"

(mapc (lambda (file) (load-file (concat (file-name-directory (or load-file-name buffer-file-name)) (concat file ".el")))) '(
    "uuidgen"
    "a"
    "dash"
    "s"
    "f"
))
(defun meq/org-babel-expand-src-block (&optional _arg datum info params)
  "Expand the current source code block.
Expand according to the source code block's header
arguments and pop open the results in a preview buffer."
  (interactive)
  (let* ((datum (or datum (let ((org-babel-current-src-block-location (org-element-property :begin  (org-element-context))))
                            (org-with-point-at org-babel-current-src-block-location
                            (org-babel-params-from-properties lang)))))
         (info (or info (org-babel-get-src-block-info datum)))
         (lang (nth 0 info))
         (params (setf (nth 2 info)
                    (sort (org-babel-merge-params (nth 2 info) params) (lambda (el1 el2) (string< (symbol-name (car el1)) (symbol-name (car el2)))))))
         (body (setf (nth 1 info) (if (org-babel-noweb-p params :eval) (org-babel-expand-noweb-references info) (nth 1 info))))
         (expand-cmd (intern (concat "org-babel-expand-body:" lang)))
         (assignments-cmd (intern (concat "org-babel-variable-assignments:" lang)))
         (expanded (if (fboundp expand-cmd)
                    (funcall expand-cmd body params)
                    (org-babel-expand-body:generic body params (and (fboundp assignments-cmd) (funcall assignments-cmd params))))))
    (if (called-interactively-p 'any)
        (org-edit-src-code expanded (concat "*Org-Babel Preview " (buffer-name) "[ " lang " ]*"))
        expanded)))
(defun meq/get-header nil (interactive) (nth 4 (org-heading-components)))
(defun meq/get-theme-from-header nil (interactive) (s-chop-suffix "-theme.el" (meq/get-header)))

(defun meq/tangle-multi (dont-check-car &rest paths) (interactive)
    (let* ((body (meq/org-babel-expand-src-block)))
        (mapc (lambda (path) (let* ((path (f-expand (substitute-in-file-name path)))
                                    (exists (f-exists? path)))
                                (if exists
                                    (unless (string= body (s-trim (f-read path))) (f-write body 'utf-8 path))
                                    (f-write body 'utf-8 path)))) (cdr paths))
        (let* ((path (f-expand (substitute-in-file-name (car paths))))
                (exists (f-exists? path)))
            (if (or dont-check-car (not exists))
                path
                (if (string= body (s-trim (f-read path))) path "no")))))
(defun meq/tangle-path nil (interactive)
    (let* ((path (s-chop-prefix "/" (f-join (org-format-outline-path (org-get-outline-path)) (meq/get-header))))
            (exists (f-exists? path)))
        (if exists
            (if (string= (meq/org-babel-expand-src-block) (s-trim (f-read path))) "no" path)
            path)))
(defun meq/tangle-multipath (&rest paths) (interactive) (apply #'meq/tangle-multi t (add-to-list 'paths (meq/tangle-path))))
;; (setq org-id-locations-file (concat %s \".org-id-locations\"))
(setq org-src-preserve-indentation t)

(defun get-README nil (interactive)
    (let* ((README (f-expand (f-join "settings" "README.org")))
        (home-README (f-expand (f-join "~" README)))
        (home-emacs-README (f-expand (f-join "~" ".emacs.d" README)))
        (user-README (f-expand (f-join "/home/shadowrylander/aiern" README)))
        (user-emacs-README (f-expand (f-join "/home/shadowrylander/aiern" ".emacs.d" README)))
        (root-README (f-expand (f-join "/" README)))
        (env (getenv "SETTINGS_README"))
        (env-README (if env (f-expand (substitute-in-file-name env)) env))
        (file (cond
                ((f-exists? README) README)
                ((f-exists? home-README) home-README)
                ((f-exists? home-emacs-README) home-emacs-README)
                ((f-exists? user-README) user-README)
                ((f-exists? user-emacs-README) user-emacs-README)
                ((f-exists? root-README) root-README)
                ((f-exists? env-README) env-README)
                (t (let* ((curl-README (shell-command-to-string "curl -fsSL https://raw.githubusercontent.com/sylvorg/settings/main/README.org 2> /dev/null")))
                        (if (string= curl-README "")
                            nil
                            (let* ((temp (make-temp-file (uuidgen-5 (uuidgen-4) (uuidgen-4)))))
                                (f-write curl-README 'utf-8 temp))))))))
    file))

(let* ((file (get-README))) (when file (org-babel-lob-ingest file)))

(defun org-hooks nil (interactive)
    (goto-char 0)
    (insert (format "#+setupfile: %s\n\n" (get-README t)))
    (goto-char 0)
    (org-ctrl-c-ctrl-c)
    (org-export-expand-include-keyword))

(mapc (lambda (hook) (interactive) (add-hook hook 'org-hooks)) '(org-babel-pre-tangle-hook org-export-before-processing-hook))
