# Case-insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Ignore hidden files unless pattern starts with dot
zstyle ':completion:*' file-patterns '*(^D~.*)'

# Show all completions without paging
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' pager false

# Prompt before showing more than 200 completions
zstyle ':completion:*' completion-query-items 200

# Show file info (like ls -F)
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' list-files true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Trailing slash for symlinked dirs
zstyle ':completion:*' mark-symlinked-directories true

# Better menu selection
zstyle ':completion:*' menu select

