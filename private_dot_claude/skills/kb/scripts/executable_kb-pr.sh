#!/usr/bin/env bash
# Publish a staged entry to the knowledge base as a branch, and print the PR link.
# The staging dir mirrors repo paths, so one call carries a whole topic folder plus
# the index edits that must land with it.
#   kb-pr.sh <staging-dir> "<title>"
set -uo pipefail

REPO="${KB_REPO:?set KB_REPO to owner/name}"
BASE="${KB_BASE:-main}"
REMOTE="${KB_REMOTE:-https://github.com/$REPO.git}"
STAGE="${1:?staging directory required}"
TITLE="${2:?title required}"

die() { echo "$*" >&2; exit 1; }

[ -d "$STAGE" ] || die "staging dir not found: $STAGE"
[ -n "$(find "$STAGE" -type f -print -quit)" ] || die "staging dir holds no files: $STAGE"

# Staged content is extracted over a clone: a symlink can write outside the tree and
# a staged .git/ would clobber the clone's own git dir.
[ -n "$(find "$STAGE" -type l -print -quit)" ] && die "staging dir contains symlinks: $STAGE"
[ -e "$STAGE/.git" ] && die "staging dir must not contain a .git directory"
while IFS= read -r rel; do
  case "/$rel/" in
    */../*) die "unsafe staged path: $rel" ;;
  esac
done < <(cd "$STAGE" && find . -mindepth 1 | sed 's|^\./||')

slug=$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' \
       | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//' | cut -c1-40)
BRANCH="kb/$(date +%Y%m%d-%H%M%S)-$$-${slug:-entry}"

WORK=$(mktemp -d) || die "cannot create temp dir"
trap 'rm -rf "$WORK"' EXIT

git clone --depth 1 --branch "$BASE" -q "$REMOTE" "$WORK" \
  || die "clone failed: $REMOTE ($BASE)"
cd "$WORK" || die "cannot enter $WORK"
git checkout -qb "$BRANCH" || die "cannot create branch $BRANCH"

( cd "$STAGE" && tar cf - . ) | tar xf - -C "$WORK" || die "staging copy failed"

git add -A
if git diff --cached --quiet; then
  die "nothing to publish — staged content already matches $BASE"
fi

echo "--- publishing ---" >&2
git diff --cached --name-status >&2

git commit -qm "kb: $TITLE" || die "commit failed"
git push -q origin "$BRANCH" || die "push failed — check credentials for $REPO"

printf 'https://github.com/%s/compare/%s...%s?expand=1\n' "$REPO" "$BASE" "$BRANCH"
