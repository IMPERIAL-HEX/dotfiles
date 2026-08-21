#!/usr/bin/env bash
# New-machine bootstrap. Reads package lists from packages.yml (same directory).
# Usage: ./bootstrap.sh            run all phases in order
#        ./bootstrap.sh apt gext   run only the named phases
# Failures append to failed.txt instead of stopping the run.

set -u
cd "$(dirname "$0")"
FAILED=failed.txt
: > "$FAILED"

log()  { printf '\n==> %s\n' "$*"; }
try()  { "$@" || echo "$*" >> "$FAILED"; }

# Pull a flat YAML list ("- item") out of a top-level key in packages.yml.
yq_list() {
  awk -v key="$1" '
    $0 ~ "^"key":" {on=1; next}
    on && /^[a-z_]+:/ {on=0}
    on && /^  - / {sub(/^  - /,""); sub(/ *#.*/,""); print}
  ' packages.yml
}

phase_repos() {
  log "apt repos and keys"
  sudo install -d -m 0755 /etc/apt/keyrings
  try sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
  fetch_key() { curl -fsSL "$1" | sudo gpg --dearmor --yes -o "/etc/apt/keyrings/$2"; }
  try fetch_key https://download.docker.com/linux/ubuntu/gpg docker.gpg
  try fetch_key https://packages.microsoft.com/keys/microsoft.asc microsoft.gpg
  try fetch_key https://updates.signal.org/desktop/apt/keys.asc signal-desktop.gpg
  try fetch_key https://packagecloud.io/slacktechnologies/slack/gpgkey slack.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/signal-desktop.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal.list >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/slack.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/slack.list >/dev/null
  # chrome, cursor, antigravity register their own repos when their .deb installs
  sudo apt-get update
}

phase_apt() {
  log "apt packages"
  for p in $(yq_list apt) docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin code google-chrome-stable signal-desktop slack-desktop; do
    try sudo apt-get install -y "$p"
  done
}

phase_installers() {
  log "scripted installers (ghostty, gcm, neovim via bob)"
  for s in installers/*.sh; do try bash "$s"; done
}

phase_snapflat() {
  log "snap and flatpak"
  try sudo snap install pinta
  try sudo snap install vlc
  try flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  try flatpak install -y flathub com.getpostman.Postman
}

phase_node() {
  log "nvm, node, pnpm, npm globals"
  [ -d "$HOME/.nvm" ] || try bash -c 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
  export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
  try nvm install 22
  try nvm install 24
  nvm alias default 24
  try npm install -g ctx7 typescript
  command -v pnpm >/dev/null || try bash -c 'curl -fsSL https://get.pnpm.io/install.sh | sh -'
}

phase_shell() {
  log "oh-my-zsh (before chezmoi apply, .zshrc expects it)"
  [ -d "$HOME/.oh-my-zsh" ] || try bash -c 'RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
}

phase_dotfiles() {
  log "chezmoi apply"
  command -v chezmoi >/dev/null || try sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  try chezmoi init --apply git@github.com:IMPERIAL-HEX/dotfiles.git
}

phase_gext() {
  log "GNOME extensions (must precede dconf load)"
  command -v pipx >/dev/null || try sudo apt-get install -y pipx
  pipx list 2>/dev/null | grep -q gnome-extensions-cli || try pipx install gnome-extensions-cli
  for e in $(yq_list gnome_extensions); do
    try "$HOME/.local/bin/gext" install "$e"
  done
}

phase_dconf() {
  log "dconf settings"
  for f in dconf/*.ini; do
    [ "$f" = dconf/extensions.ini ] && continue
    path="org/gnome/$(basename "$f" .ini | tr - /)"
    try dconf load "/$path/" < "$f"
  done
  # only after phase_gext, or the extension schemas do not exist yet
  try dconf load /org/gnome/shell/extensions/ < dconf/extensions.ini
}

phase_chsh() {
  log "login shell"
  [ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] || try chsh -s "$(command -v zsh)"
}

ALL=(repos apt installers snapflat node shell dotfiles gext dconf chsh)
PHASES=("${@:-${ALL[@]}}")
for ph in "${PHASES[@]}"; do "phase_$ph"; done

log "done"
if [ -s "$FAILED" ]; then
  echo "Failed steps (rerun individually):"
  cat "$FAILED"
else
  echo "No failures. Log out and back in for the shell change."
fi
