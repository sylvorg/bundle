;; org-tangle-functions.el

;; The tangle functions are adapted from [[https://emacs.stackexchange.com/a/29884/31428][this answer on the emacs Stack Exchange]], written by [[https://emacs.stackexchange.com/users/2710/andrew-swann][Andrew Swann]]:


;; [[file:README.org::*org-tangle-functions.el][org-tangle-functions.el:1]]
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
    (if (member (system-name) '("argus" "bastiodon")) meq/tangle-path "no"))

(let* ((README "settings/README.org")
        (file (cond
                ((file-exists-p README) README)
                ((file-exists-p (concat "home/.emacs.d/" README)) (concat "home/.emacs.d/" README))
                ((file-exists-p (concat "~/" README)) (concat "~/" README))
                ((file-exists-p (concat "~/.emacs.d/" README)) (concat "~/.emacs.d/" README))
                ((file-exists-p (concat "/" README)) (concat "/" README)))))
    (when file (org-babel-lob-ingest file)))
;; org-tangle-functions.el:1 ends here
