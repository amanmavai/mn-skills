#!/usr/bin/env bash
#
# sync.sh — materialize all skills from this repo into the live agent skills dir.
#
# Source of truth : this repo, grouped as mine/<skill>/ and vendor/<source>/<skill>/
# Live dir        : ~/.agents/skills (flat, one dir per skill — this is what tools scan)
# Convenience link: ~/.claude/skills -> ~/.agents/skills
#
# A "skill" is any directory containing a SKILL.md file. Its directory name
# becomes its name in the flat live dir, so names must be unique across sources.
#
# Usage:
#   ./sync.sh            rebuild the live dir from this repo

set -euo pipefail

# --- Configuration -----------------------------------------------------------
# ${BASH_SOURCE[0]} — the path to this script file itself
#  dirname "…" — strips the filename, leaving the directory containing the script
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # repo root (/Users/amanmavai/mn/repos/mn-skills)
DEST="${HOME}/.agents/skills"                              # flat live dir tools scan
CLAUDE_LINK="${HOME}/.claude/skills"                       # convenience symlink -> DEST

# --- Helpers -----------------------------------------------------------------
info()  { printf '\n\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
fail()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# --- Argument parsing --------------------------------------------------------
case "${1:-}" in
  "" ) ;;
  -h|--help) sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  * ) fail "Unknown arg: $1 (usage: $0)" ;;
esac

# --- 1. Rebuild the live dir from mine/ and vendor/ --------------------------
# Convention: a skill is any dir with a SKILL.md, and its basename is unique
# across sources. That lets the live dir double as the collision check — a name
# that's already there means two skills claim it, so we stop.
info "Rebuilding $DEST from mine/ and vendor/ ..."
# Start clean. rm -rf handles every prior state — missing (-f is quiet), a real
# dir, or a stray symlink (the link is removed, never followed into its target).
rm -rf "$DEST"
mkdir -p "$DEST"

count=0
# Read one NUL-terminated path per SKILL.md (-d '' pairs with find's -print0).
while IFS= read -r -d '' skillmd; do
  src="$(dirname "$skillmd")"    # the skill's dir  (…/tdd/SKILL.md -> …/tdd)
  name="$(basename "$src")"      # its live name    (…/tdd          -> tdd)
  # DEST started empty, so a name already there means a second skill claims it.
  [ ! -e "$DEST/$name" ] || fail "COLLISION: '$name' — two skills share a directory name. Rename one and re-run."
  echo "  + $name"
  cp -R "$src" "$DEST/$name"     # copy the whole skill dir, not just SKILL.md
  count=$((count + 1))
# Process substitution (not a pipe) keeps the loop in this shell so count survives.
# find lists every SKILL.md under both roots, NUL-separated (-print0) for safe paths.
done < <(find "$REPO_DIR/mine" "$REPO_DIR/vendor" -type f -name SKILL.md -print0 2>/dev/null)
ok "Copied $count skill(s) into $DEST"

# --- 3. Ensure ~/.claude/skills -> ~/.agents/skills --------------------------
# -L is tested before -e since every symlink also passes -e.
if [ -L "$CLAUDE_LINK" ]; then # [ -L ... ] — "is it a symlink?"
  target="$(readlink "$CLAUDE_LINK")" # readlink reads where the link points into target
  if [ "$target" != "$DEST" ]; then # only act if it points somewhere wrong. If it already points at $DEST, do nothing 
    ln -sfn "$DEST" "$CLAUDE_LINK"
    ok "Relinked $CLAUDE_LINK -> $DEST"
  fi
elif [ -e "$CLAUDE_LINK" ]; then #  it exists but is NOT a symlink
  warn "$CLAUDE_LINK exists and is not a symlink — leaving it untouched."
  warn "Move it aside if you want it linked to $DEST."
else # it doesn't exist at all
  mkdir -p "$(dirname "$CLAUDE_LINK")" # creates the parent dir (~/.claude) if it's missing
  ln -sfn "$DEST" "$CLAUDE_LINK" # creates the link fresh
  ok "Linked $CLAUDE_LINK -> $DEST"
fi

# --- Done --------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Synced $count skill(s) to $DEST"
echo "============================================="
