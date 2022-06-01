(eval-when-compile (require 'subr-x))

(defun meq/get-header nil (interactive)
    (nth 4 (org-heading-components)))
(defun meq/tangle-path nil (interactive)
    (string-remove-prefix "/" (concat
        (org-format-outline-path (org-get-outline-path)) "/"
            (meq/get-header))))
(defun meq/get-theme-from-header nil (interactive)
    (string-remove-suffix "-theme.el" (meq/get-header)))
(defun meq/tangle-on-relay nil (interactive)
    (if (member (system-name) '()) meq/tangle-path "no"))

;; (setq org-id-locations-file (concat %s \".org-id-locations\"))
(setq org-src-preserve-indentation t)

(let* ((README "settings/README.org")
        (file (cond
                ((file-exists-p README) README)
                ((file-exists-p (concat "home/.emacs.d/" README)) (concat "home/.emacs.d/" README))
                ((file-exists-p (concat "~/" README)) (concat "~/" README))
                ((file-exists-p (concat "~/.emacs.d/" README)) (concat "~/.emacs.d/" README))
                ((file-exists-p (concat "/" README)) (concat "/" README)))))
    (when file (org-babel-lob-ingest file)))
