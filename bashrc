# ~/.bashrc for Minimal sessions (loadout-claude-emacs).
#
# The daemon's attach shell is `bash --noprofile --rcfile <daemon rc>`, and
# that rc sources this file; ~/.bash_profile is never read. The daemon rc has
# already installed the __minimal_attach_env DEBUG trap that refreshes TERM on
# re-attach, so a DEBUG trap set here would have to call it (none is set).

# A fresh `min session attach` lands here outside tmux: enter the tmux
# session. Pane shells (TMUX set) and non-terminal shells do nothing.
if [ -z "${TMUX:-}" ] && [ -t 1 ]; then
  "$HOME/.local/bin/dev-tmux"
fi
