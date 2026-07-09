#!/usr/bin/env bash
#
# update.sh — (re)vendor mattpocock/skills into this folder.
#
# Clones the upstream repo, replaces the category dirs here with its skills/
# tree, and pins the commit in SOURCE.md. Re-run any time to refresh; the git
# diff afterward shows exactly what changed upstream.
#
# Usage:
#   ./update.sh          vendor/refresh the skills
#   ./update.sh --sync   ...then run the repo's sync.sh to update the live dir

set -euo pipefail

REPO_URL="https://github.com/mattpocock/skills.git"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # vendor/matt-pocock
ROOT="$(cd "$DEST/../.." && pwd)"                        # repo root

DO_SYNC=0
case "${1:-}" in
  --sync) DO_SYNC=1 ;;
  "" ) ;;
  * ) echo "unknown arg: $1" >&2; echo "usage: $0 [--sync]" >&2; exit 2 ;;
esac

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/mp-skills.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

echo "Cloning $REPO_URL ..."
git clone --depth 1 "$REPO_URL" "$STAGE" >/dev/null 2>&1
SHA="$(git -C "$STAGE" rev-parse HEAD)"

if [ ! -d "$STAGE/skills" ]; then
  echo "ERROR: upstream has no skills/ directory — layout changed?" >&2
  exit 1
fi

echo "Replacing vendored skills (keeping update.sh, SOURCE.md) ..."
# Remove only the category directories; leave this script and SOURCE.md.
find "$DEST" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
cp -R "$STAGE"/skills/. "$DEST"/

cat > "$DEST/SOURCE.md" <<EOF
# Source: mattpocock/skills

- Repo:   https://github.com/mattpocock/skills
- Commit: $SHA
- Vendored: $(date +%Y-%m-%d)

Refresh with \`./update.sh\` in this folder (add \`--sync\` to also rebuild the
live dir). Prune \`deprecated/\` and \`in-progress/\` here if you don't want those.
EOF

n="$(find "$DEST" -name SKILL.md | wc -l | tr -d ' ')"
echo "Vendored $n skill(s) @ ${SHA:0:7}"

if [ "$DO_SYNC" -eq 1 ]; then
  echo "Running sync.sh ..."
  "$ROOT/sync.sh"
else
  echo "Next: run $ROOT/sync.sh to update the live dir."
fi
