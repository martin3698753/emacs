(defvar elpaca-installer-version 0.5)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil
                              :files (:defaults (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (call-process "git" nil buffer t "clone"
                                       (plist-get order :repo) repo)))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(setq package-enable-at-startup nil)


  ;; Install use-package support
  (elpaca elpaca-use-package
    ;; Enable :elpaca use-package keyword.
    (elpaca-use-package-mode)
    ;; Assume :elpaca t unless otherwise specified.
    (setq elpaca-use-package-by-default t))

  ;; Block until current queue processed.
  (elpaca-wait)

  ;;When installing a package which modifies a form used at the top-level
  ;;(e.g. a package which adds a use-package key word),
  ;;use `elpaca-wait' to block until that package has been installed/configured.
  ;;For example:
  ;;(use-package general :demand t)
  ;;(elpaca-wait)


  ;;Turns off elpaca-use-package-mode current declartion
  ;;Note this will cause the declaration to be interpreted immediately (not deferred).
  ;;Useful for configuring built-in emacs features.
  (use-package emacs :elpaca nil :config (setq ring-bell-function #'ignore))

  ;; Don't install anything. Defer execution of BODY
  ;;(elpaca nil (message "deferred"))

;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (evil-mode))
(use-package evil-collection
  :after evil
  :config
  (setq evil-collection-mode-list '(dashboard dired ibuffer))
  (evil-collection-init))
(use-package evil-tutor)

;; Using RETURN to follow links in Org/Evil 
;; Unmap keys in 'evil-maps if not done, (setq org-return-follows-link t) will not work
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil))
  ;; Setting RETURN key in org-mode to follow links
  (setq org-return-follows-link  t)

(use-package general
  :config
  (general-evil-setup)

  (general-create-definer martin/leader-keys
      :states '(normal insert visual emacs)
      :keymaps 'override
      :prefix "SPC"
      :global-prefix "M-SPC")

  (martin/leader-keys
   "b" '(:ignore t :wk "buffer")
   "bb" '(switch-to-buffer :wk "Switch buffer")
   "bk" '(kill-this-buffer :wk "Kill this buffer")
   "bn" '(next-buffer :wk "Next buffer")
   "bp" '(previous-buffer :wk "Previous buffer")
   "bi" '(ibuffer :wk "IBuffer")
   "br" '(revert-buffer :wk "Reload buffer"))

  (martin/leader-keys
   "e" '(:ignore t :wk "Evaluate")
   "er" '(eval-region :wk "Evaluate elisp in region")
   "eb" '(eval-buffer :wk "Evaluate buffer"))

  (martin/leader-keys
   "." '(find-file :wk "Find file")
   "SPC" '(counsel-M-x :wk "Counsel M-x")
   "TAB" '(comment-line :wk "Comment lines"))

  (martin/leader-keys
   "h" '(:ignore t :wk "Help")
   "hf" '(describe-function :wk "Describe function")
   "hv" '(describe-variable :wk "Describe variable"))


  (martin/leader-keys
   "w" '(:ignore t :wk "Window")
   ;; Window splits
   "wc" '(evil-window-delete :wk "Close window")
   "wn" '(evil-window-new :wk "New window")
   "ws" '(evil-window-split :wk "Horizontal split window")
   "wv" '(evil-window-vsplit :wk "Vertical split window")
   ;; Window motions
   "wh" '(evil-window-left :wk "Window left")
   "wj" '(evil-window-down :wk "Window down")
   "wk" '(evil-window-up :wk "Window up")
   "wl" '(evil-window-right :wk "Window right")
   "ww" '(evil-window-next :wk "Goto next window"))

  (martin/leader-keys
   "t" '(:ignore t :wk "Toggle")
   "tv" '(vterm-toggle :wk "Toggle vterm")
   "tn" '(neotree-toggle :wk "Toggle neotree"))
  )

(server-start)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(global-display-line-numbers-mode 1)
(global-visual-line-mode t)

(use-package toc-org
:commands toc-org-enable
:init (add-hook 'org-mode-hook 'toc-org-enable))

(add-hook 'org-mode-hook 'org-indent-mode)
(use-package org-bullets)
(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))

(use-package lua-mode)



(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(setq backup-directory-alist '((".*" . "~/.local/share/Trash/files")))

(use-package company
  :defer 2
  :diminish
  :custom
  (company-begin-commands '(self-insert-command))
  (company-idle-delay .1)
  (company-minimum-prefix-length 2)
  (company-show-numbers t)
  (company-tooltip-align-annotations 't)
  (global-company-mode t))

(use-package company-box
  :after company
  :diminish
  :hook (company-mode . company-box-mode))

(use-package dashboard
  :ensure t
  :config
  (setq initial-buffer-choice 'dashboard-open)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-banner-logo-title "Welcome to Emacs")
  (setq dashboard-startup-banner 'logo) ;; use default logo, replace with "path.png"
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents . 5)
                        ;;(agenda . 5 )
                        ;;(bookmarks . 3)
                        ;;(registers . 3)
                        ))
  :custom
  (dashboard-modify-heading-icons '((recents . "file-text")
                                    (bookmarks . "book")))
  :config
  (dashboard-setup-startup-hook))

(use-package diminish)

(use-package dired-open
   :config

     (evil-define-key 'normal dired-mode-map (kbd "h") 'dired-up-directory)
     (evil-define-key 'normal dired-mode-map (kbd "l") 'dired-open-file))
(use-package dired-preview
  :config
  (setq dired-preview-binary-as-hexl t)
  (setq dired-preview-delay 0.3)
  (setq dired-preview-max-size (expt 2 20))
  (setq dired-preview-ignored-extensions-regexp
        (concat "\\."
                "\\(mkv\\|webm\\|mp4\\|mp3\\|ogg\\|m4a"
                "\\|gz\\|zst\\|tar\\|xz\\|rar\\|zip"
                "\\|iso\\|epub)"))
  (dired-preview-global-mode 1))


; (use-package peep-dired
;   :after dired
;   :hook (evil-normalize-keymaps . peep-dired-hook)
;   :config
;     (evil-define-key 'normal peep-dired-mode-map (kbd "h") 'dired-up-directory)
;     (evil-define-key 'normal peep-dired-mode-map (kbd "l") 'dired-open-file) ; use dired-find-file instead if not using dired-open package
;     (evil-define-key 'normal peep-dired-mode-map (kbd "j") 'peep-dired-next-file)
;     (evil-define-key 'normal peep-dired-mode-map (kbd "k") 'peep-dired-prev-file)
;     (evil-define-key 'normal peep-dired-mode-map (kbd "k") 'peep-dired-prev-file)
;     (setq peep-dired-cleanup-eagerly t)
; )
;(add-hook 'peep-dired-hook 'evil-normalize-keymaps)

(set-face-attribute 'default nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "JetBrains Mono"
  :height 120
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
  :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-11"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.12)

(use-package hl-todo
:hook ((org-mode . hl-todo-mode)
       (prog-mode . hl-todo-mode))
:config
(setq hl-todo-highlight-punctuation ":"
      hl-todo-keyword-faces
      `(("TODO"       warning bold)
        ("FIXME"      error bold)
        ("HACK"       font-lock-constant-face bold)
        ("REVIEW"     font-lock-keyword-face bold)
        ("NOTE"       success bold)
        ("DEPRECATED" font-lock-doc-face bold))))

(use-package counsel
  :after ivy
  :config (counsel-mode))

(use-package ivy
  :bind
  ;; ivy-resume resumes the last Ivy-based completion.
  (("C-c C-r" . ivy-resume)
   ("C-x B" . ivy-switch-buffer-other-window))
  :custom
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (setq enable-recursive-minibuffers t)
  :config
  (ivy-mode))

(use-package all-the-icons-ivy-rich
  :ensure t
  :init (all-the-icons-ivy-rich-mode 1))

(use-package ivy-rich
  :after ivy
  :ensure t
  :init (ivy-rich-mode 1) ;; this gets us descriptions in M-x.
  :custom
  (ivy-virtual-abbreviate 'full
   ivy-rich-switch-buffer-align-virtual-buffer t
   ivy-rich-path-style 'abbrev)
  :config
  (ivy-set-display-transformer 'ivy-switch-buffer
                               'ivy-rich-switch-buffer-transformer))

(global-set-key [escape] 'keyboard-escape-quit)

(use-package neotree
  :config
  (setq neo-smart-open t
        neo-show-hidden-files t
        neo-window-width 35
        neo-window-fixed-size nil
        inhibit-compacting-font-caches t)
        ;; truncate long file names in neotree
        (add-hook 'neo-after-create-hook
           #'(lambda (_)
               (with-current-buffer (get-buffer neo-buffer-name)
                 (setq truncate-lines t)
                 (setq word-wrap nil)
                 (make-local-variable 'auto-hscroll-mode)
                 (setq auto-hscroll-mode nil)))))

(use-package pdf-tools
  :ensure t
  :bind (:map pdf-view-mode-map
              ("j" . pdf-view-next-line-or-next-page)
              ("k" . pdf-view-previous-line-or-previous-page)
              )
  :config
  (pdf-tools-install t)
  (setq-default pdf-view-display-size 'fit-page)
  (setq pdf-annot-activate-created-annotations t)
  (add-hook 'pdf-view-mode-hook (lambda ()
                                  (bms/pdf-midnite-amber)));dark mode
  (add-hook 'pdf-view-mode-hook #'(lambda () (interactive) (display-line-numbers-mode -1)))
  )

(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

;; eshell-syntax-highlighting -- adds fish/zsh-like syntax highlighting.
;; eshell-rc-script -- your profile for eshell; like a bashrc for eshell.
;; eshell-aliases-file -- sets an aliases file for the eshell.

(setq eshell-rc-script (concat user-emacs-directory "eshell/profile")
      eshell-aliases-file (concat user-emacs-directory "eshell/aliases")
      eshell-history-size 5000
      eshell-buffer-maximum-lines 5000
      eshell-hist-ignoredups t
      eshell-scroll-to-bottom-on-input t
      eshell-destroy-buffer-when-process-dies t
      eshell-visual-commands'("bash" "fish" "htop" "ssh" "top" "zsh"))

(use-package vterm
:config
(setq shell-file-name "/bin/fish"
      vterm-max-scrollback 5000))

(use-package vterm-toggle
:after vterm
:config
(setq vterm-toggle-fullscreen-p nil)
(setq vterm-toggle-scope 'project)
(add-to-list 'display-buffer-alist
             '((lambda (buffer-or-name _)
                   (let ((buffer (get-buffer buffer-or-name)))
                     (with-current-buffer buffer
                       (or (equal major-mode 'vterm-mode)
                           (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                (display-buffer-reuse-window display-buffer-at-bottom)
                ;;(display-buffer-reuse-window display-buffer-in-direction)
                ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                ;;(direction . bottom)
                ;;(dedicated . t) ;dedicated is supported in emacs27
                (reusable-frames . visible)
                (window-height . 0.3))))

(use-package sudo-edit
:config
(martin/leader-keys
"fu" '(sudo-edit :wk "Sudo edit file")
"fU" '(sudo-edit-find-file :wk "Sudo find file"))
)

(use-package rainbow-delimiters
  :hook ((emacs-lisp-mode . rainbow-delimiters-mode)
         (clojure-mode . rainbow-delimiters-mode)))

(use-package rainbow-mode
:hook org-mode prog-mode)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 35      ;; sets modeline height
        doom-modeline-bar-width 5    ;; sets right bar width
        doom-modeline-persp-name t   ;; adds perspective name to modeline
        doom-modeline-persp-icon t)) ;; adds folder icon next to persp name

(add-to-list 'custom-theme-load-path "~/.config/emacs/themes/")

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Load theme
  (load-theme 'doom-one t)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  ;; (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  ;; (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; (load-theme 'doom-one t)

(add-to-list 'default-frame-alist '(alpha-background . 90))

(use-package which-key
:init
(which-key-mode 1)
:config
(setq which-key-side-window-location 'bottom
which-key-sort-order #'which-key-key-order-alpha
which-key-sort-uppercase-first nil
which-key-add-column-padding 1
which-key-max-display-columns nil
which-key-min-display-lines 6
which-key-side-window-slot -10
which-key-side-window-max-height 0.25
which-key-idle-delay 0.8
which-key-max-description-length 25
which-key-allow-imprecise-window-fit t
which-key-separator " -> " ))
