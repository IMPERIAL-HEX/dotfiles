#!/usr/bin/env bash
# Install bob (neovim version manager) to ~/.local/bin, then the latest stable neovim.
# The active nvim lives at ~/.local/share/bob/nvim-bin/nvim; env.zsh puts that dir on PATH.
set -eu
bin="$HOME/.local/bin"
mkdir -p "$bin"
if ! command -v bob >/dev/null; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/bob.zip" \
    "$(curl -fsSL https://api.github.com/repos/MordechaiHadad/bob/releases/latest |
       grep -o '"browser_download_url": *"[^"]*bob-linux-x86_64\.zip"' | cut -d'"' -f4 | head -1)"
  unzip -q -o "$tmp/bob.zip" -d "$tmp"
  install -m 0755 "$tmp"/bob-linux-x86_64/bob "$bin/bob"
fi
"$bin/bob" use stable
"$HOME/.local/share/bob/nvim-bin/nvim" --version | head -1
