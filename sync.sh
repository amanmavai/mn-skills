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
#   ./sync.sh --dry-run  show what would happen, change nothing
#   ./sync.sh -n         alias for --dry-run

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.agents/skills"
CLAUDE_LINK="${HOME}/.claude/skills"

DRY_RUN=0
case "${1:-}" in
  -n|--dry-run) DRY_RUN=1 ;;
  "" ) ;;
  * ) echo "unknown arg: $1" >&2; echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] $*"; else eval "$@"; fi; }

# --- 1. Collect skills from mine/ and vendor/ -------------------------------
# Find every SKILL.md, map its parent dir -> skill name (basename).
# (Kept bash-3.2 compatible — macOS ships 3.2, which has no associative arrays.)
SRC_DIRS=()
NAMES=()
collisions=0

# Return the source dir already claimed for a name, or nothing.
claimed_by() {
  local want="$1" i
  [ "${#NAMES[@]}" -eq 0 ] && return 1
  for i in "${!NAMES[@]}"; do
    if [ "${NAMES[$i]}" = "$want" ]; then
      printf '%s' "${SRC_DIRS[$i]}"
      return 0
    fi
  done
  return 1
}

while IFS= read -r -d '' skillmd; do
  dir="$(dirname "$skillmd")"
  name="$(basename "$dir")"
  if prev="$(claimed_by "$name")"; then
    say "COLLISION: '$name'"
    say "    already: $prev"
    say "    also   : $dir"
    collisions=1
  else
    SRC_DIRS+=("$dir")
    NAMES+=("$name")
  fi
done < <(find "$REPO_DIR/mine" "$REPO_DIR/vendor" -type f -name SKILL.md -print0 2>/dev/null)

if [ "$collisions" -ne 0 ]; then
  say ""
  say "Aborting: two or more skills share a directory name. Rename one and re-run."
  exit 1
fi

count="${#NAMES[@]}"
say "Found $count skill(s) in repo."

# --- 2. Rebuild the live dir ------------------------------------------------
if [ -L "$DEST" ]; then
  # DEST should be a real dir, not a symlink; drop a stray link.
  run "rm -f '$DEST'"
elif [ -d "$DEST" ]; then
  run "rm -rf '$DEST'"
fi
run "mkdir -p '$DEST'"

if [ "$count" -gt 0 ]; then
  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"
    src="${SRC_DIRS[$i]}"
    say "  + $name"
    run "cp -R '$src' '$DEST/$name'"
  done
fi

# --- 3. Ensure ~/.claude/skills -> ~/.agents/skills -------------------------
if [ -L "$CLAUDE_LINK" ]; then
  target="$(readlink "$CLAUDE_LINK")"
  if [ "$target" != "$DEST" ]; then
    run "ln -sfn '$DEST' '$CLAUDE_LINK'"
    say "  relinked $CLAUDE_LINK -> $DEST"
  fi
elif [ -e "$CLAUDE_LINK" ]; then
  say "WARNING: $CLAUDE_LINK exists and is not a symlink — leaving it untouched."
  say "         Move it aside if you want it linked to $DEST."
else
  run "mkdir -p '$(dirname "$CLAUDE_LINK")'"
  run "ln -sfn '$DEST' '$CLAUDE_LINK'"
  say "  linked $CLAUDE_LINK -> $DEST"
fi

say ""
if [ "$DRY_RUN" -eq 1 ]; then
  say "Dry run complete — nothing changed."
else
  say "Synced $count skill(s) to $DEST"
fi
