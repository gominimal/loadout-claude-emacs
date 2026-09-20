;;; init.el --- Personal Minimal-session Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Personal init for Minimal sessions, applied by the loadout-claude-emacs loadout.
;;
;; Elisp libraries and tree-sitter grammars come from the emacs-site-lisp
;; package; language servers come from their own MPR/sideload packages.
;; Everything here is wired with the built-in use-package.  Site-lisp
;; packages carry no autoloads files, so deferred entries always declare
;; their triggers (:bind/:mode/:commands) and eager ones use :demand.

;;; Code:

;; ── General settings ─────────────────────────────────────────────────
(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function 'ignore
      use-short-answers t
      create-lockfiles nil
      require-final-newline t
      sentence-end-double-space nil
      custom-file (expand-file-name "custom.el" user-emacs-directory))

;; with xterm-mouse-mode on below we need this for copy to macOS clipboard
(setq xterm-tmux-extra-capabilities '(modifyOtherKeys setSelection))

;; Mouse drag copies the region to the kill ring, which (via OSC 52)
;; lands in the macOS clipboard — so select-with-mouse then Cmd-V works.
(setq mouse-drag-copy-region t)

;; OSC 52 outside tmux too: TERM=xterm-ghostty goes through
;; terminal-init-xterm, whose `check' auto-detection doesn't recognise
;; Ghostty; declare the capabilities explicitly (same as the tmux var).
(setq xterm-extra-capabilities '(modifyOtherKeys setSelection))

(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

(column-number-mode 1)
(global-display-line-numbers-mode 1)
(show-paren-mode 1)
(electric-pair-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(xterm-mouse-mode 1)                    ; mouse support inside tmux
(mouse-wheel-mode 1)                    ; bind <wheel-up>/<wheel-down> on TTY

(load-theme 'modus-vivendi t)

(setq scroll-margin 3
      scroll-conservatively 101)

(setq-default indent-tabs-mode nil
              tab-width 4)

;; Built-in in Emacs 30
(which-key-mode 1)
(editorconfig-mode 1)

;; ── Minibuffer completion (vertico + orderless + marginalia) ─────────
(use-package vertico
  :demand t
  :config (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :config (marginalia-mode 1))

(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x p b" . consult-project-buffer)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g f"   . consult-flymake)
         ("M-s l"   . consult-line)
         ("M-s r"   . consult-ripgrep)
         ("M-s f"   . consult-fd)
         ("C-x r b" . consult-bookmark))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; ── In-buffer completion (corfu, rendered via popon in the TTY) ──────
(use-package corfu
  :demand t
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.15
        corfu-auto-prefix 2
        corfu-cycle t)
  (global-corfu-mode 1))

(use-package cape
  :demand t
  :config
  (add-hook 'completion-at-point-functions #'cape-file 90)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 91))

;; ── Editable grep buffers ────────────────────────────────────────────
(use-package wgrep
  :commands (wgrep-change-to-wgrep-mode)
  :init (setq wgrep-auto-save-buffer t))

;; ── Magit ────────────────────────────────────────────────────────────
(use-package magit
  :bind (("C-x g" . magit-status)))

;; ── Language modes without a built-in ts-mode ────────────────────────
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)))

(use-package nickel-mode
  :mode "\\.ncl\\'")

(use-package zig-mode
  :mode "\\.\\(zig\\|zon\\)\\'"
  :init (setq zig-format-on-save nil))   ; zls formats via eglot instead

(use-package haskell-ts-mode
  :mode "\\.hs\\'")

;; ── Tree-sitter grammars and mode registrations ──────────────────────
(setq treesit-font-lock-level 4)

;; Grammar shared libraries from the emacs-site-lisp package.
(add-to-list 'treesit-extra-load-path "/usr/lib/emacs/tree-sitter")

;; File extensions with no classic-mode entry to remap.
(dolist (entry '((rust       . ("\\.rs\\'"      . rust-ts-mode))
                 (go         . ("\\.go\\'"      . go-ts-mode))
                 (gomod      . ("go\\.mod\\'"   . go-mod-ts-mode))
                 (typescript . ("\\.ts\\'"      . typescript-ts-mode))
                 (tsx        . ("\\.tsx\\'"     . tsx-ts-mode))
                 (lua        . ("\\.lua\\'"     . lua-ts-mode))
                 (dockerfile . ("\\(?:^\\|/\\)\\(?:Dockerfile\\|Containerfile\\)\\(?:\\..*\\)?\\'"
                                . dockerfile-ts-mode))))
  (when (treesit-language-available-p (car entry))
    (add-to-list 'auto-mode-alist (cdr entry))))

;; Languages whose classic mode already claims the extension: remap.
(dolist (entry '((python . (python-mode . python-ts-mode))
                 (bash   . (sh-mode     . bash-ts-mode))
                 (c      . (c-mode      . c-ts-mode))
                 (cpp    . (c++-mode    . c++-ts-mode))
                 (java   . (java-mode   . java-ts-mode))
                 (ruby   . (ruby-mode   . ruby-ts-mode))
                 (json   . (js-json-mode . json-ts-mode))
                 (yaml   . (yaml-mode   . yaml-ts-mode))
                 (toml   . (conf-toml-mode . toml-ts-mode))))
  (when (treesit-language-available-p (car entry))
    (add-to-list 'major-mode-remap-alist (cdr entry))))

;; yaml has no built-in classic mode; give the extensions to yaml-ts-mode.
(when (treesit-language-available-p 'yaml)
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode)))

;; ── Project detection ────────────────────────────────────────────────
;; Recognise language-specific marker files as project roots so eglot
;; sends the correct workspace root to LSP servers (instead of always
;; defaulting to the git root).
(setq project-vc-extra-root-markers
      '("Cargo.toml" "go.mod" "package.json" "tsconfig.json"
        "pyproject.toml" "setup.py" "compile_commands.json"
        "CMakeLists.txt" "meson.build" "pom.xml" "build.gradle"
        "settings.gradle" "build.gradle.kts" "Gemfile" "build.zig"
        "stack.yaml" "cabal.project" "minimal.toml"))

;; ── xref navigation (M-. / M-,) ──────────────────────────────────────
;; Remove the etags backend so M-. never prompts "Visit TAGS table".
;; Eglot adds its own xref backend when active; this fallback gives a
;; clear message when no LSP server is running.
(remove-hook 'xref-backend-functions #'etags--xref-backend)

(defun my/xref-no-tags-backend () 'no-tags)
(cl-defmethod xref-backend-identifier-at-point ((_backend (eql 'no-tags)))
  (thing-at-point 'symbol t))
(cl-defmethod xref-backend-definitions ((_backend (eql 'no-tags)) identifier)
  (user-error "No LSP server running for `%s'" identifier))
(cl-defmethod xref-backend-references ((_backend (eql 'no-tags)) _identifier)
  (user-error "No LSP server running"))
(add-hook 'xref-backend-functions #'my/xref-no-tags-backend 100)

;; ── Eglot (LSP) ──────────────────────────────────────────────────────
;; Emacs 30 ships eglot with built-in entries for go (gopls), rust
;; (rust-analyzer), python (pyright), typescript/js
;; (typescript-language-server), bash, c/c++ (clangd), and java (jdtls).
;; Add the servers it doesn't know, and override ruby onto ruby-lsp.
(setq eglot-autoshutdown t
      eglot-events-buffer-config '(:size 0 :format full))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(nickel-mode . ("nls")))
  (add-to-list 'eglot-server-programs '(zig-mode . ("zls")))
  (add-to-list 'eglot-server-programs '(haskell-ts-mode . ("haskell-language-server-wrapper" "--lsp")))
  (add-to-list 'eglot-server-programs '(lua-ts-mode . ("lua-language-server")))
  (add-to-list 'eglot-server-programs '((ruby-mode ruby-ts-mode) . ("ruby-lsp"))))

;; Auto-start eglot for programming modes.  eglot-ensure silently does
;; nothing when no server is configured for the mode.
(defun my/maybe-eglot ()
  "Start eglot unless this is an emacs-lisp buffer."
  (unless (derived-mode-p 'emacs-lisp-mode)
    (eglot-ensure)))
(add-hook 'prog-mode-hook #'my/maybe-eglot)

;; Format on save via LSP, but only when the server actually supports
;; formatting (pyright, for one, does not — an unconditional
;; eglot-format-buffer in before-save-hook would abort every save).
(defun my/eglot-format-on-save ()
  (when (and (eglot-managed-p)
             (eglot-server-capable :documentFormattingProvider))
    (ignore-errors (eglot-format-buffer))))
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'my/eglot-format-on-save nil t)))

;; ── Python extras: ruff diagnostics + formatting next to pyright ─────
;; Eglot replaces flymake's backends in managed buffers, so re-add
;; flymake-ruff from eglot-managed-mode-hook.
(use-package flymake-ruff
  :commands (flymake-ruff-load))

(defun my/python-ruff-setup ()
  (when (and (derived-mode-p 'python-base-mode)
             (executable-find "ruff"))
    (flymake-ruff-load)
    (add-hook 'before-save-hook #'my/ruff-format-buffer nil t)))
(add-hook 'eglot-managed-mode-hook #'my/python-ruff-setup)

(defun my/ruff-format-buffer ()
  "Format the current python buffer with `ruff format', keeping point."
  (interactive)
  (when (and (derived-mode-p 'python-base-mode)
             (executable-find "ruff")
             buffer-file-name)
    (let ((pt (point))
          (tmp (generate-new-buffer " *ruff-format*")))
      (unwind-protect
          (when (zerop (call-process-region (point-min) (point-max)
                                            "ruff" nil tmp nil
                                            "format" "--stdin-filename"
                                            buffer-file-name "-"))
            (replace-buffer-contents tmp)
            (goto-char pt))
        (kill-buffer tmp)))))

;; ── JS/TS extras: eslint diagnostics next to the language server ─────
(use-package flymake-eslint
  :commands (flymake-eslint-enable))

(defun my/maybe-flymake-eslint ()
  (when (and (derived-mode-p 'typescript-ts-mode 'tsx-ts-mode 'js-mode 'js-ts-mode)
             (executable-find "eslint")
             (locate-dominating-file
              default-directory
              (lambda (dir)
                (seq-some (lambda (f) (file-exists-p (expand-file-name f dir)))
                          '("eslint.config.js" "eslint.config.mjs"
                            ".eslintrc.json" ".eslintrc.js" ".eslintrc.yml")))))
    (flymake-eslint-enable)))
(add-hook 'eglot-managed-mode-hook #'my/maybe-flymake-eslint)

;;; init.el ends here
