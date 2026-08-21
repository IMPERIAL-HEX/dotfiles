#!/usr/bin/env bash
# Mirror the live skill at ~/.claude/skills/kb back into the repo as a PR, so the
# repo copy never drifts from the one actually being invoked.
set -uo pipefail

LIVE="${KB_SKILL_LIVE:-$HOME/.claude/skills/kb}"
[ -d "$LIVE" ] || { echo "live skill not found: $LIVE" >&2; exit 1; }

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

STAGE=$(mktemp -d) || exit 1
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/.claude/skills/kb"
( cd "$LIVE" && tar cf - . ) | tar xf - -C "$STAGE/.claude/skills/kb" || exit 1

exec "$HERE/kb-pr.sh" "$STAGE" "sync /kb skill from ~/.claude/skills/kb"
