# Environment for every zsh invocation, loaded by ~/.zshenv.

export LANG=en_US.UTF-8
export EDITOR=nvim

typeset -U path PATH
# bob's nvim-bin must precede /usr/local/bin while an old manual nvim lingers there
path=("$HOME/.local/bin" "$HOME/.local/share/bob/nvim-bin" $path "$HOME/go/bin")

export PNPM_HOME="$HOME/.local/share/pnpm"
path=("$PNPM_HOME" $path)
export PATH

# knowledge base — consumed by the /kb capture skill
export KB_REPO="IMPERIAL-HEX/knowledge-base"
export KB_LOCAL="$HOME/work/knowledge-extraction/knowledge-base"
export KB_BASE="main"
