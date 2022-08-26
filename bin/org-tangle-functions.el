(setq org-export-functions-directory (file-name-directory (or load-file-name buffer-file-name))
      windows (member system-type '(windows-nt ms-dos)))
(defun meq/oefd (&rest args) (apply #'concat org-export-functions-directory (mapcar #'(lambda (arg) (concat (if windows "\\" "/") arg)) args)))
(mapc (lambda (file) (load-file (meq/oefd (concat file ".el")))) '(
    "uuidgen"
    "a"
    "dash"
    "s"
    "f-shortdoc"
    "f"
))
(defun meq/org-babel-tangle-fn-27 (by-fn)
    (let ((file-name (car by-fn)))
	     (when file-name
               (let ((lspecs (cdr by-fn))
		     (fnd (file-name-directory file-name))
		     modes make-dir she-banged lang)
	         ;; drop source-blocks to file
	         ;; We avoid append-to-file as it does not work with tramp.
	         (with-temp-buffer
		   (mapc
		    (lambda (lspec)
		      (let* ((block-lang (car lspec))
			     (spec (cdr lspec))
			     (get-spec (lambda (name) (cdr (assq name (nth 4 spec)))))
			     (she-bang (let ((sheb (funcall get-spec :shebang)))
				         (when (> (length sheb) 0) sheb)))
			     (tangle-mode (funcall get-spec :tangle-mode)))
		        (unless (string-equal block-lang lang)
			  (setq lang block-lang)
			  (let ((lang-f (org-src-get-lang-mode lang)))
			    (when (fboundp lang-f) (ignore-errors (funcall lang-f)))))
		        ;; if file contains she-bangs, then make it executable
		        (when she-bang
			  (unless tangle-mode (setq tangle-mode #o755)))
		        (when tangle-mode
			  (add-to-list 'modes tangle-mode))
		        ;; Possibly create the parent directories for file.
		        (let ((m (funcall get-spec :mkdirp)))
			  (and m fnd (not (string= m "no"))
			       (setq make-dir t)))
		        ;; Handle :padlines unless first line in file
		        (unless (or (string= "no" (funcall get-spec :padline))
				    (= (point) (point-min)))
			  (insert "\n"))
		        (when (and she-bang (not she-banged))
			  (insert (concat she-bang "\n"))
			  (setq she-banged t))
		        (org-babel-spec-to-string spec)
		        (setq block-counter (+ 1 block-counter))))
		    lspecs)
		   (when make-dir
		     (make-directory fnd 'parents))
                   ;; erase previous file
                   (when (file-exists-p file-name)
                     (delete-file file-name))
		   (write-region nil nil file-name)
		   (mapc (lambda (mode) (set-file-modes file-name mode)) modes)
                   (push file-name path-collector))))))

(defun meq/org-babel-tangle-fn-28 (by-fn)
    (let ((block-lang (car by-fn)))
        (mapc (lambda (spec)
                (let* ((get-spec (lambda (name) (cdr (assq name (nth 4 spec)))))
                        (file-name (let ((fn (funcall get-spec :tangle)))
                                      (cond ((string= fn "yes") (concat (file-name-sans-extension (nth 1 (cadr by-fn))) "." block-lang))
                                        ((string= fn "no") nil)
                                        (t fn)))))
                    (when file-name
                        (with-temp-buffer
                            (let ((fnd (file-name-directory file-name))
                                    (she-bang (let ((sheb (funcall get-spec :shebang)))
                                                (when (> (length sheb) 0) sheb)))
                                    (tangle-mode (funcall get-spec :tangle-mode))
                                    modes make-dir she-banged lang)
                                (unless (string-equal block-lang lang)
                                    (setq lang block-lang)
                                    (let ((lang-f (org-src-get-lang-mode lang)))
                                        (when (fboundp lang-f) (ignore-errors (funcall lang-f)))))
                                (when she-bang (unless tangle-mode (setq tangle-mode #o755)))
                                (when tangle-mode (add-to-list 'modes tangle-mode))
                                (let ((m (funcall get-spec :mkdirp)))
                                    (and m fnd (not (string= m "no")) (setq make-dir t)))
                                (unless (or (string= "no" (funcall get-spec :padline))
                                            (= (point) (point-min)))
                                    (insert "\n"))
                                (when (and she-bang (not she-banged))
                                    (insert (concat she-bang "\n")))
                                    (setq she-banged t)
                                (org-babel-spec-to-string spec)
                                (setq block-counter (+ 1 block-counter))
                                (when make-dir (make-directory fnd 'parents))
                                (when (file-exists-p file-name) (delete-file file-name))
                                (write-region nil nil file-name)
                                (mapc (lambda (mode) (set-file-modes file-name mode)) modes)
                                (push file-name path-collector)))))) (cdr by-fn))))

(defun meq/org-babel-tangle (&optional arg target-file lang-re)
  "Write code blocks to source-specific files.
Extract the bodies of all source code blocks from the current
file into their own source-specific files.
With one universal prefix argument, only tangle the block at point.
When two universal prefix arguments, only tangle blocks for the
tangle file of the block at point.
Optional argument TARGET-FILE can be used to specify a default
export file for all source blocks.  Optional argument LANG-RE can
be used to limit the exported source code blocks by languages
matching a regular expression."
  (interactive "P")
  (run-hooks 'org-babel-pre-tangle-hook)
  ;; Possibly Restrict the buffer to the current code block
  (save-restriction
    (save-excursion
      (when (equal arg '(4))
	(let ((head (org-babel-where-is-src-block-head)))
	  (if head
	      (goto-char head)
	    (user-error "Point is not in a source code block"))))
      (let ((block-counter 0)
	    (org-babel-default-header-args
	     (if target-file
		 (org-babel-merge-params org-babel-default-header-args
					 (list (cons :tangle target-file)))
	       org-babel-default-header-args))
	    (tangle-file
	     (when (equal arg '(16))
	       (or (cdr (assq :tangle (nth 2 (org-babel-get-src-block-info 'light))))
		   (user-error "Point is not in a source code block"))))
	    path-collector)

    ;; (mapc (intern (concat "meq/org-babel-tangle-fn-" (if (version<= "28.1" emacs-version) "28" "27")))
    ;;     (if (equal arg '(4))
    ;;         (org-babel-tangle-single-block 1 t)
  	;;         (org-babel-tangle-collect-blocks lang-re tangle-file)))

    (mapc #'meq/org-babel-tangle-fn-28
        (if (equal arg '(4))
            (org-babel-tangle-single-block 1 t)
  	        (org-babel-tangle-collect-blocks lang-re tangle-file)))

	(message "Tangled %d code block%s from %s" block-counter
		 (if (= block-counter 1) "" "s")
		 (file-name-nondirectory
		  (buffer-file-name
		   (or (buffer-base-buffer)
                       (current-buffer)
                       (and (org-src-edit-buffer-p)
                            (org-src-source-buffer))))))
	;; run `org-babel-post-tangle-hook' in all tangled files
	(when org-babel-post-tangle-hook
	  (mapc
	   (lambda (file)
	     (org-babel-with-temp-filebuffer file
	       (run-hooks 'org-babel-post-tangle-hook)))
	   path-collector))
	path-collector))))

(advice-add #'org-babel-tangle :override #'meq/org-babel-tangle)
(defun meq/org-babel-expand-src-block (&optional light datum info params)
  "Expand the current source code block. Expand according to the source code block's header arguments."
  (let* ((info (or info (org-babel-get-src-block-info t datum)))
         (lang (nth 0 info))
         (params (setf (nth 2 info)
                    (sort (org-babel-merge-params (nth 2 info) params) (lambda (el1 el2) (string< (symbol-name (car el1)) (symbol-name (car el2)))))))
         (params (setf (nth 2 info)
                    (if light params (mapcar (lambda (param) (cons (car param) (org-babel-read (cdr param))))
                                        (-remove (lambda (param) (member (car param) '(:tangle))) params)))))
         (body (setf (nth 1 info) (if (org-babel-noweb-p params :eval) (org-babel-expand-noweb-references info) (nth 1 info))))
         (expand-cmd (intern (concat "org-babel-expand-body:" lang)))
         (assignments-cmd (intern (concat "org-babel-variable-assignments:" lang)))
         (expanded (if (fboundp expand-cmd)
                    (funcall expand-cmd body params)
                    (org-babel-expand-body:generic body params (and (fboundp assignments-cmd) (funcall assignments-cmd params)))))
         (expanded (if (a-has-key? params :shebang)
                    (concat (a-get params :shebang) "\n" expanded)
                    expanded)))
    expanded))
(defun meq/org-babel-expand (path &optional return-path light no-check body info parent-buffer datum params)
    (let* ((exists (and path (f-exists? path)))
            (body (if exists (s-trim (f-read path)) body))
            (args (list light datum info params))
            (path-or-body (if return-path path (apply #'meq/org-babel-expand-src-block args))))
        (if (and (not no-check) body)
            (if exists
                (if (string= body (if return-path (apply #'meq/org-babel-expand-src-block args) path-or-body))
                    (if return-path "no")
                    path-or-body)
                path-or-body)
            path-or-body)))
(defun meq/get-block (name &optional light parent-buffer datum params)
    (let* (path return-path no-check body)
        (meq/org-babel-expand path return-path light no-check body (org-babel-lob--src-info name) parent-buffer datum params)))
(defun meq/get-header nil (nth 4 (org-heading-components)))
(defun meq/get-theme-from-header nil (s-chop-suffix "-theme.el" (meq/get-header)))

(defun meq/tangle-multi (light dont-check-car &rest paths)
    (mapc (lambda (path) (let* ((body (meq/org-babel-expand (f-expand (substitute-in-file-name path)) nil light)))
                            (if body (f-write body 'utf-8 path)))) (cdr paths))
    (meq/org-babel-expand (f-expand (substitute-in-file-name (car paths))) t light dont-check-car))

(defun meq/tangle-path (&optional light)
    (meq/org-babel-expand (s-chop-prefix "/" (f-join (org-format-outline-path (org-get-outline-path)) (meq/get-header))) t light))
(defun meq/tangle-multipath (&rest paths) (apply #'meq/tangle-multi nil 'dont-check-car (add-to-list 'paths (meq/tangle-path))))
(defun meq/tangle-multipath-light (&rest paths) (apply #'meq/tangle-multi 'light 'dont-check-car (add-to-list 'paths (meq/tangle-path t))))
(defun get-README (&optional return-link setupfile lobfile) (interactive)
    (let* ((README (f-join "settings" "README.org"))
        (settings-README (f-expand (s-chop-prefix "/" (f-join (org-format-outline-path (org-get-outline-path)) "README.org"))))
        (flake-settings (s-trim (shell-command-to-string "nix eval --impure --expr \"((builtins.getFlake or import) (toString ./.)).inputs.settings.outPath\" | tr -d '\"' 2> /dev/null")))
        (flake-README (unless (s-blank? flake-settings) (f-expand (f-join flake-settings "README.org"))))
        (repo-README (f-expand README))
        (home-README (f-expand (f-join "~" README)))
        (user-README (f-expand (f-join "/home/shadowrylander/aiern" README)))
        (root-README (f-expand (f-join "/" README)))
        (env (getenv "SETTINGS_README"))
        (env-README (unless (s-blank? env) (f-expand (substitute-in-file-name env))))
        (file (or (when setupfile (f-expand setupfile))
                  (when lobfile (f-expand lobfile))
                  (cond
                    ((f-exists? README) (concat "./" README))
                    ((and (f-exists? settings-README) (equal (last (f-split settings-README) 2) '("settings" "README.org"))) settings-README)
                    ((f-exists? flake-README) flake-README)
                    ((f-exists? repo-README) repo-README)
                    ((f-exists? home-README) home-README)
                    ((f-exists? user-README) user-README)
                    ((f-exists? root-README) root-README)
                    ((unless (s-blank? env) (f-exists? env-README)) env-README)
                    (t (if return-link
                        "https://raw.githubusercontent.com/sylvorg/settings/main/README.org"
                        (let* ((curl-README (shell-command-to-string "curl -fsSL https://raw.githubusercontent.com/sylvorg/settings/main/README.org 2> /dev/null")))
                            (unless (s-blank? curl-README)
                                (let* ((temp (make-temp-file (uuidgen-5 (uuidgen-4) (uuidgen-4)))))
                                    (f-write curl-README 'utf-8 temp)
                                    temp)))))))))
    file))

(defvar current-lob-file nil)
(defvar current-setup-file nil)

(defun org-babel-pre-tangle-hooks nil (interactive)
    (setq org-elements (let* (
            (headlines (org-element-map
                        (org-element-parse-buffer 'headline)
                        'headline
                        (lambda (headline) (downcase (org-element-property :title headline)))))
            (keywords (org-element-map
                        (org-element-parse-buffer 'element)
                        'keyword
                        (lambda (keyword) (cons (downcase (org-element-property :key keyword)) (org-element-property :value keyword))))))
        (unless (or (a-has-key? keywords "nosetupfile") (a-has-key? keywords "nosetuplobfile") (member "no setupfile" headlines))
              (setq current-setup-file (get-README 'return-link (when (a-has-key? keywords "setuplobfile") (a-get keywords "setuplobfile"))))
              (when debug (let* ((m (format "Current Setup File: %s" current-setup-file))
                                  (l (length m))
                                  (b (make-string l ?=)))
                            (message "\n\n%s\n%s\n%s\n\n" b m b)))
              (when (member current-setup-file expanded-args) (global-auto-revert-mode 1))
              (goto-char 0)
              (insert (format "#+setupfile: %s\n\n" current-setup-file))
              (goto-char 0)
              (org-ctrl-c-ctrl-c))
        (a-list :keywords keywords :headlines headlines)))
    (setq org-src-preserve-indentation t)
    (let* ((headlines (a-get org-elements :headlines))
            (keywords (a-get org-elements :keywords)))
        (unless (or (a-has-key? keywords "nolobfile") (a-has-key? keywords "nosetuplobfile") (member "no lobfile" headlines))
          (let* ((file (get-README nil nil (cond ((a-has-key? keywords "setuplobfile") (a-get keywords "setuplobfile"))
                                            ((a-has-key? keywords "lobfile") (a-get keywords "lobfile"))))))
            (when file
              (setq current-lob-file file)
              (when debug (let* ((m (format "Current LOB File: %s" current-lob-file))
                                  (l (length m))
                                  (b (make-string l ?=)))
                            (message "\n\n%s\n%s\n%s\n\n" b m b)))
              (when (member current-lob-file expanded-args) (global-auto-revert-mode 1))
              (org-babel-lob-ingest current-lob-file)))))
    (org-export-expand-include-keyword))

(defun org-babel-post-tangle-hooks nil (interactive)
  (when (or (member current-setup-file expanded-args) (member current-lob-file expanded-args)) (global-auto-revert-mode -1))
)

(mapc (lambda (hook) (interactive) (add-hook hook 'org-babel-pre-tangle-hooks)) '(org-babel-pre-tangle-hook org-export-before-processing-hook))
(mapc (lambda (hook) (interactive) (add-hook hook 'org-babel-post-tangle-hooks)) '(org-babel-post-tangle-hook org-export-after-processing-hook))
