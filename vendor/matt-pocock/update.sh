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

set -euo pipefail

# --- Configuration -----------------------------------------------------------
REPO_URL="https://github.com/mattpocock/skills.git"
# ${BASH_SOURCE[0]} — the path to this script file itself
#  dirname "…" — strips the filename, leaving the directory containing the script
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # vendor/matt-pocock (/Users/amanmavai/mn/repos/mn-skills/vendor/matt-pocock)
ROOT="$(cd "$DEST/../.." && pwd)"                        # repo root (/Users/amanmavai/mn/repos/mn-skills)

# --- Helpers -----------------------------------------------------------------
info()  { printf '\n\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
fail()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# --- Argument parsing --------------------------------------------------------
case "${1:-}" in
  "" ) ;;
  -h|--help) sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  * ) fail "Unknown arg: $1 (usage: $0)" ;;
esac

# --- 1. Clone upstream into a scratch dir ------------------------------------
# mktemp keeps the working tree clean and lets `trap` guarantee cleanup even if
# a later step aborts under `set -e`.
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/mn-skills.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

info "Cloning $REPO_URL ..."
# clone the upstream repo into the temp staging dir created earlier
git clone --depth 1 "$REPO_URL" "$STAGE" >/dev/null 2>&1 \
  || fail "git clone failed (network down, or repo moved?)"
# captures the hash into SHA
SHA="$(git -C "$STAGE" rev-parse HEAD)"

# Guard against an upstream layout change: everything below assumes skills/.
#  -d test asks does this path exist and is it a directory
[ -d "$STAGE/skills" ] || fail "Upstream has no skills/ directory — layout changed?"
ok "Cloned @ ${SHA:0:7}"

# --- 2. Replace the vendored tree --------------------------------------------
# Remove only the category directories; keep this script and SOURCE.md, which
# live at DEST root and are ours, not upstream's.
info "Replacing vendored skills (keeping update.sh, SOURCE.md) ..."
# delete top-level subdirs of DEST (-type d spares the root files update.sh/SOURCE.md)
find "$DEST" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
cp -R "$STAGE"/skills/. "$DEST"/
ok "Copied upstream skills/ into $DEST"

# --- 3. Pin the source commit ------------------------------------------------
cat > "$DEST/SOURCE.md" <<EOF
# Source: mattpocock/skills

- Repo:   https://github.com/mattpocock/skills
- Commit: $SHA
- Vendored: $(date +%Y-%m-%d)

Refresh with \`./update.sh\` in this folder. Prune \`deprecated/\` and
\`in-progress/\` here if you don't want those.
EOF
ok "Pinned commit in SOURCE.md"

n="$(find "$DEST" -name SKILL.md | wc -l | tr -d ' ')"

# --- Done --------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Vendored $n skill(s) @ ${SHA:0:7}"
echo "============================================="
info "Next: run $ROOT/sync.sh to update the live dir."
