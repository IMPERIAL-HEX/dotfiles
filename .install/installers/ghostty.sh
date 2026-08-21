#!/usr/bin/env bash
# Install or upgrade ghostty from the ghostty-ubuntu community .deb (no apt repo exists).
set -eu
ubu="$(. /etc/os-release && echo "$VERSION_ID")"
url="$(curl -fsSL https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest |
  grep -o "\"browser_download_url\": *\"[^\"]*amd64_${ubu}.deb\"" | cut -d'"' -f4 | head -1)"
[ -n "$url" ] || { echo "no ghostty .deb for Ubuntu $ubu" >&2; exit 1; }
latest="$(basename "$url" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)"
current="$(dpkg-query -W -f '${Version}' ghostty 2>/dev/null | grep -o '^[0-9.]*' || true)"
if [ "$current" = "$latest" ]; then echo "ghostty $current is current"; exit 0; fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/ghostty.deb" "$url"
sudo apt-get install -y --allow-downgrades "$tmp/ghostty.deb"
ghostty --version | head -1
