#!/usr/bin/env bash
# Install or upgrade git-credential-manager from GitHub releases (no apt repo exists).
# .gitconfig points at /usr/local/bin/git-credential-manager, which the .deb provides.
set -eu
url="$(curl -fsSL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest |
  grep -o '"browser_download_url": *"[^"]*linux_amd64[^"]*\.deb"' | cut -d'"' -f4 | head -1)"
[ -n "$url" ] || { echo "no gcm .deb found" >&2; exit 1; }
latest="$(basename "$url" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)"
current="$(dpkg-query -W -f '${Version}' gcm 2>/dev/null || true)"
if [ "$current" = "$latest" ]; then echo "gcm $current is current"; exit 0; fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/gcm.deb" "$url"
sudo apt-get install -y "$tmp/gcm.deb"
git-credential-manager --version
