#!/usr/bin/env bash
#
# sync.sh — copy all skills from this repo into the live agent skills dir.
#
# Source of truth : this repo, grouped as mine/<skill>/ and vendor/<source>/<skill>/
# Live dir        : ~/.agents/skills (flat, one dir per skill — this is what tools scan)
# Convenience link: ~/.claude/skills -> ~/.agents/skills
#
# A "skill" is any directory containing a SKILL.md file. Its directory name
# becomes its name in the flat live dir, so names must be unique across sources.
# Only skills this script copied last time are replaced; other entries are kept.
#
# Usage:
#   ./sync.sh            copy the repo's skills into the live dir

set -euo pipefail

# --- Configuration -----------------------------------------------------------
# ${BASH_SOURCE[0]} — the path to this script file itself
#  dirname "…" — strips the filename, leaving the directory containing the script
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # repo root (/Users/amanmavai/mn/repos/mn-skills)
DEST="${HOME}/.agents/skills"                              # flat live dir tools scan
CLAUDE_LINK="${HOME}/.claude/skills"                       # convenience symlink -> DEST
MANIFEST="$DEST/.mn-skills-manifest"                       # names this script copied last run

# --- Helpers -----------------------------------------------------------------
info()  { printf '\n\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
fail()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# in_list <name> <newline-separated list> — exact whole-line match.
in_list() { printf '%s\n' "$2" | grep -Fxq -- "$1"; }

# --- Argument parsing --------------------------------------------------------
case "${1:-}" in
  "" ) ;;
  -h|--help) sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  * ) fail "Unknown arg: $1 (usage: $0)" ;;
esac

# --- 1. Collect skills and check names, before touching the live dir ---------
# Convention: a skill is any dir with a SKILL.md, and its basename is unique
# across sources. Every check happens here, so a failure leaves DEST as it was.
info "Collecting skills from mine/ and vendor/ ..."
srcs=()     # skill dirs to copy
names=""    # their basenames, one per line
# Read one NUL-terminated path per SKILL.md (-d '' pairs with find's -print0).
while IFS= read -r -d '' skillmd; do
  src="$(dirname "$skillmd")"    # the skill's dir  (…/tdd/SKILL.md -> …/tdd)
  name="$(basename "$src")"      # its live name    (…/tdd          -> tdd)
  ! in_list "$name" "$names" || fail "COLLISION: '$name' — two skills share a directory name. Rename one and re-run."
  names="${names}${name}"$'\n'
  srcs+=("$src")
# Process substitution (not a pipe) keeps the loop in this shell so the vars survive.
# find lists every SKILL.md under both roots, NUL-separated (-print0) for safe paths.
done < <(find "$REPO_DIR/mine" "$REPO_DIR/vendor" -type f -name SKILL.md -print0 2>/dev/null)
[ "${#srcs[@]}" -gt 0 ] || fail "No skills found under mine/ or vendor/."

# The manifest says which entries in DEST are ours. With no manifest yet (first
# run of this version), assume the current skill names are ours — the old
# script owned the whole dir, so anything matching them came from it.
if [ -f "$MANIFEST" ]; then owned="$(cat "$MANIFEST")"; else owned="$names"; fi

# A DEST symlink would make us write into whatever it points at.
[ ! -L "$DEST" ] || fail "$DEST is a symlink — replace it with a real dir and re-run."
# Never overwrite an entry someone else put in DEST (e.g. the app's synced/).
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if { [ -e "$DEST/$name" ] || [ -L "$DEST/$name" ]; } && ! in_list "$name" "$owned"; then
    fail "'$name' already exists in $DEST and sync.sh didn't put it there. Move it aside or rename the skill, then re-run."
  fi
done <<< "$names"
ok "Found ${#srcs[@]} skill(s), no name conflicts"

# --- 2. Replace our previous copies in the live dir --------------------------
info "Copying skills into $DEST ..."
mkdir -p "$DEST"
# Remove only what we copied last time, so skills deleted from the repo go away
# too. Skip anything that isn't a plain name — rm -rf must stay inside DEST.
while IFS= read -r name; do
  case "$name" in ''|.|..|*/*) continue ;; esac
  rm -rf "${DEST:?}/$name"
done <<< "$owned"

for src in "${srcs[@]}"; do
  name="$(basename "$src")"
  echo "  + $name"
  cp -R "$src" "$DEST/$name"     # copy the whole skill dir, not just SKILL.md
done
printf '%s' "$names" > "$MANIFEST"
ok "Copied ${#srcs[@]} skill(s) into $DEST"

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
echo "  Synced ${#srcs[@]} skill(s) to $DEST"
echo "============================================="
