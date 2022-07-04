(setq org-export-functions-directory (file-name-directory (or load-file-name buffer-file-name))
      windows (member system-type '(windows-nt ms-dos)))
(defun meq/oefd (&rest args) (apply #'concat org-export-functions-directory (mapcar #'(lambda (arg) (concat (if windows "\\" "/") arg)) args)))
(load-file (meq/oefd "org-tangle-functions.el"))
(defun meq/org-html-src-block (src-block _contents info)
  "Transcode a SRC-BLOCK element from Org to HTML.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (if (org-export-read-attribute :attr_html src-block :textarea)
      (org-html--textarea-block src-block)
    (let* ((lang (org-element-property :language src-block))
           (lang (cond ((member lang '("emacs-lisp")) "lisp")
                       ((member lang '("shell" "zsh" "bash")) "sh")
                       ((member lang '("text")) "plaintext")
                       (t lang)))
           (code (org-html-format-code src-block info))
           (label (let ((lbl (org-html--reference src-block info t)))
                    (if lbl (format " id=\"%s\"" lbl) "")))
           (klipsify  (and  (plist-get info :html-klipsify-src)
                            (member lang '("javascript" "js"
                                           "ruby" "scheme" "clojure" "php" "html")))))
      (if (not lang) (format "<pre class=\"example\"%s>\n%s</pre>" label code)
        (format "<div class=\"org-src-container\">\n%s%s\n</div>"
                ;; Build caption.
                (let ((caption (org-export-get-caption src-block)))
                  (if (not caption) ""
                    (let ((listing-number
                           (format
                            "<span class=\"listing-number\">%s </span>"
                            (format
                             (org-html--translate "Listing %d:" info)
                             (org-export-get-ordinal
                              src-block info nil #'org-html--has-caption-p)))))
                      (format "<label class=\"org-src-name\">%s%s</label>"
                              listing-number
                              (org-trim (org-export-data caption info))))))
                ;; Contents.
                (if klipsify
                    (format "<pre><code class=\"src src-%s\"%s%s>%s</code></pre>"
                            lang
                            label
                            (if (string= lang "html")
                                " data-editor-type=\"html\""
                              "")
                            code)
                  (format "<pre><code class=\"language-%s match-braces rainbow-braces\"%s>%s</code></pre>"
                          lang label code)))))))
        (advice-add #'org-html-src-block :override #'meq/org-html-src-block)
(defun meq/org-html-inline-src-block (inline-src-block _contents info)
  "Transcode an INLINE-SRC-BLOCK element from Org to HTML.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (let* ((lang (org-element-property :language inline-src-block))
         (code (org-html-fontify-code
                (org-element-property :value inline-src-block)
                lang))
         (label
          (let ((lbl (org-html--reference inline-src-block info t)))
            (if (not lbl) "" (format " id=\"%s\"" lbl)))))
    (format "<code class=\"language-%s match-braces rainbow-braces\"%s>%s</code>" lang label code)))
(advice-add #'org-html-inline-src-block :override #'meq/org-html-inline-src-block)
(defun meq/org-html-format-headline-default-function
    (todo _todo-type priority text tags info)
  "Default format function for a headline.
See `org-html-format-headline-function' for details."
  (let ((todo (org-html--todo todo info))
        (priority (org-html--priority priority info))
        (tags (org-html--tags tags info)))
    (concat todo (and todo " ")
            priority (and priority " ")
            text
            (and tags "&#xa0;") tags)))
(advice-add #'org-html-format-headline-default-function :override #'meq/org-html-format-headline-default-function)
