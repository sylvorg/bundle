(setq org-functions-directory (file-name-directory (or load-file-name buffer-file-name))
      windows (member system-type '(windows-nt ms-dos)))
(defun meq/oefd (&rest args) (apply #'concat org-functions-directory (mapcar #'(lambda (arg) (concat (if windows "\\" "/") arg)) args)))
(mapc (lambda (file) (unless (require file nil t) (load-file (meq/oefd (symbol-name file) (concat (symbol-name file) ".el"))))) '(
    uuidgen
    a
    dash
    s
))
(mapc (lambda (file) (unless (require file nil t) (load-file (meq/oefd "f" (concat (symbol-name file) ".el"))))) '(
    f-shortdoc
    f
    riot
))
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

(defun meq/tangle-multi-inner (light dont-check-car &rest paths)
    (let* ((paths (remove "no" paths)))
      (mapc (lambda (path) (let* ((path (f-expand (substitute-in-file-name path)))
                                  (parent (f-parent path))
                                  (body (meq/org-babel-expand path nil light)))
                              (when body
                                    (unless (f-exists? parent) (f-mkdir-full-path parent))
                                    (f-write (if (string-suffix-p "\n" body) body (concat body "\n")) 'utf-8 path)))) (cdr paths))
      (meq/org-babel-expand (f-expand (substitute-in-file-name (car paths))) t light dont-check-car)))

(defun meq/tangle-path (&optional light)
    (meq/org-babel-expand (s-chop-prefix "/" (f-join (org-format-outline-path (org-get-outline-path)) (meq/get-header))) t light))
(defun meq/tangle-multipath (&rest paths) (apply #'meq/tangle-multi-inner nil 'dont-check-car (add-to-list 'paths (meq/tangle-path))))
(defun meq/tangle-multipath-light (&rest paths) (apply #'meq/tangle-multi-inner 'light 'dont-check-car (add-to-list 'paths (meq/tangle-path t))))
(defun meq/tangle-multi (&rest paths) (apply #'meq/tangle-multi-inner nil nil paths))
(defun meq/tangle-multi-light (&rest paths) (apply #'meq/tangle-multi-inner 'light nil paths))
(defun link-or-file (lf return-link &optional substitute is-link) (interactive)
    (when (and lf (not (s-blank? lf)))

        ;; TODO: Is `return-link' is causing this to happen?
        ;;       Or maybe `is-link'?

        ;; ========================================
        ;; Current Setup File: ../bundle/README.org
        ;; ========================================

        (if (and (not is-link) (f-exists? (setq expanded-lf (f-expand (if substitute (substitute-in-file-name lf) lf)))))
            expanded-lf
            (if return-link
                lf
                (let* ((curl-README (shell-command-to-string (format "curl -fsSL %s 2> /dev/null" lf))))
                    (unless (s-blank? curl-README)
                        (let* ((temp (make-temp-file (uuidgen-5 (uuidgen-4) (uuidgen-4)))))
                            (f-write curl-README 'utf-8 temp)
                            temp)))))))
(defvar bundle-path nil)
(defvar use-nix-path nil)
(defvar nix-path nil)
(defun join-and-expand (&rest paths) (f-expand (apply #'f-join paths)))
(defun get-README (&optional return-link setupfile lobfile) (interactive)
    (let* ((README (f-join "bundle" "README.org"))
            ;; This gets the directory of the file being tangled or exported,
            ;; so that the `bundle-README' condition can check if it's a bundle README.
            (tangled-fd (f-expand (s-chop-prefix "/" (org-format-outline-path (org-get-outline-path)))))

            (userrepo (f-expand "/home/shadowrylander/aiern"))
            (user-README (join-and-expand userrepo README))
            (usernamerepo (f-expand "/home/shadowrylander/shadowrylander"))
            (username-README (join-and-expand usernamerepo README)))
        (or (link-or-file bundle-path return-link)
            (link-or-file (getenv "BUNDLE_README") return-link t)
            (link-or-file setupfile return-link)
            (link-or-file lobfile return-link)
            (let* ((bundle-README (join-and-expand tangled-fd "README.org")))
                (cond
                  ((f-exists? README) (concat "./" README))
                  ((and (f-exists? bundle-README) (equal (last (f-split bundle-README) 2) '("bundle" "README.org"))) bundle-README)
                  ((and (f-ancestor-of? userrepo tangled-fd) (f-exists? user-README)) user-README)
                  ((and (f-ancestor-of? usernamerepo tangled-fd) (f-exists? username-README)) username-README)))
            (when use-nix-path (link-or-file nix-path return-link))
            (let* ((flake-bundle (s-trim (shell-command-to-string "nix eval --impure --expr \"((builtins.getFlake or import) (toString ./.)).inputs.bundle.outPath\" | tr -d '\"' 2> /dev/null"))))
                (cond
                  (f-present? (unless (s-blank? flake-bundle) (join-and-expand flake-bundle "README.org")))
                  (f-present? (f-expand README))
                  (f-present? (join-and-expand "~" README))
                  (f-present? user-README)
                  (f-present? username-README)
                  (f-present? (join-and-expand "/" README))))
            (link-or-file nix-path return-link)
            (link-or-file "https://raw.githubusercontent.com/sylvorg/bundle/main/README.org" return-link t))))

(defvar current-lob-file nil)
(defvar current-setup-file nil)

(defun org-babel-pre-tangle-hooks (&optional html) (interactive)
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
              (org-babel-lob-ingest current-lob-file))))))

(defun org-babel-post-tangle-hooks nil (interactive)
  (when (or (member current-setup-file expanded-args) (member current-lob-file expanded-args)) (global-auto-revert-mode -1))
)

(mapc (lambda (hook) (interactive) (add-hook hook 'org-babel-pre-tangle-hooks)) '(org-babel-pre-tangle-hook org-export-before-processing-hook))
(mapc (lambda (hook) (interactive) (add-hook hook 'org-babel-post-tangle-hooks)) '(org-babel-post-tangle-hook org-export-after-processing-hook))
