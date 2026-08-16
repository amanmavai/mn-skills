#!/usr/bin/env bash
#
# vendor.sh — (re)vendor skills from any git repo into vendor/<name>/.
#
# Clones the upstream repo, copies its skills folder into vendor/<name>/, and
# pins the commit in vendor/<name>/SOURCE.md. Re-run any time to refresh; the
# git diff afterward shows exactly what changed upstream.
#
# Usage:
#   ./vendor.sh <repo-url> [name] [--dir <subdir>]
#   ./vendor.sh                        refresh every already-vendored source
#
#   <repo-url>   https://github.com/owner/repo(.git) or git@github.com:owner/repo.git
#   [name]       folder under vendor/ (default: the repo owner)
#   --dir        folder inside the repo holding the skills (default: skills, "." = root)
#
# Examples:
#   ./vendor.sh https://github.com/mattpocock/skills.git matt-pocock
#   ./vendor.sh https://github.com/some/repo --dir .claude/skills

set -euo pipefail

# --- Configuration -----------------------------------------------------------
# ${BASH_SOURCE[0]} — the path to this script file itself
#  dirname "…" — strips the filename, leaving the directory containing the script
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # repo root (/Users/amanmavai/mn/repos/mn-skills)
VENDOR_DIR="$ROOT/vendor"                              # where vendored sources live
DEFAULT_SUBDIR="skills"                                # upstream folder holding the skills

# --- Helpers -----------------------------------------------------------------
info()  { printf '\n\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
fail()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# owner/repo out of either URL form, so we can name things and print nicely.
#   https://github.com/mattpocock/skills.git -> mattpocock/skills
#   git@github.com:mattpocock/skills.git     -> mattpocock/skills
repo_slug() {
  local url="$1"
  url="${url%.git}"          # drop trailing .git
  url="${url%/}"             # drop trailing slash
  url="${url##*github.com}"  # drop everything up to the host
  url="${url#[:/]}"          # drop the : or / that followed it
  printf '%s' "$url"
}

# --- Argument parsing --------------------------------------------------------
REPO_URL=""
NAME=""
SUBDIR="$DEFAULT_SUBDIR"

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dir)     SUBDIR="${2:-}"; [ -n "$SUBDIR" ] || fail "--dir needs a value"; shift 2 ;;
    -*)        fail "Unknown flag: $1 (see $0 --help)" ;;
    *)
      if   [ -z "$REPO_URL" ]; then REPO_URL="$1"
      elif [ -z "$NAME" ];     then NAME="$1"
      else fail "Unexpected arg: $1 (see $0 --help)"
      fi
      shift ;;
  esac
done

# --- Scratch cleanup ---------------------------------------------------------
# One clone at a time, so a single global is enough to guarantee cleanup on any
# exit path (success, `set -e` abort, or fail's explicit exit).
STAGE=""
cleanup() { if [ -n "$STAGE" ]; then rm -rf "$STAGE"; fi; }
trap cleanup EXIT

# --- Vendor one source -------------------------------------------------------
# vendor_one <repo-url> <name> <subdir>
vendor_one() {
  local repo_url="$1" name="$2" subdir="$3"
  local dest="$VENDOR_DIR/$name"
  local slug; slug="$(repo_slug "$repo_url")"

  # mktemp keeps the working tree clean; the EXIT trap set above guarantees
  # cleanup even if a later step aborts under `set -e` or calls fail.
  STAGE="$(mktemp -d "${TMPDIR:-/tmp}/mn-skills.XXXXXX")"

  info "Cloning $repo_url ..."
  git clone --depth 1 "$repo_url" "$STAGE" >/dev/null 2>&1 \
    || fail "git clone failed (network down, or repo moved?)"
  local sha; sha="$(git -C "$STAGE" rev-parse HEAD)"

  # Guard against an upstream layout change: everything below assumes $subdir.
  #  -d test asks does this path exist and is it a directory
  local src="$STAGE/$subdir"
  [ -d "$src" ] || fail "Upstream $slug has no '$subdir/' directory — layout changed? (try --dir)"
  ok "Cloned $slug @ ${sha:0:7}"

  # Replace the vendored tree wholesale. Everything under vendor/<name>/ is
  # upstream's (SOURCE.md is rewritten below), so a clean slate is safe.
  info "Replacing vendor/$name ..."
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
  # A repo-root vendor (--dir .) drags .git along; it must not nest inside ours.
  rm -rf "$dest/.git"
  ok "Copied $slug:$subdir/ into vendor/$name"

  # Pin the source commit. The Repo/Skills dir lines are also what the no-arg
  # refresh reads back, so keep their shape stable.
  cat > "$dest/SOURCE.md" <<EOF
# Source: $slug

- Repo:   $repo_url
- Skills dir: $subdir
- Commit: $sha
- Vendored: $(date +%Y-%m-%d)

Refresh with \`./vendor.sh\` from the repo root. Prune any category folders
here you don't want — they come back on the next refresh.
EOF
  ok "Pinned commit in vendor/$name/SOURCE.md"

  local n; n="$(find "$dest" -name SKILL.md | wc -l | tr -d ' ')"
  echo "  -> $n skill(s) @ ${sha:0:7}"
  TOTAL=$((TOTAL + n))

  rm -rf "$STAGE"; STAGE=""
}

# Pull a `- Key: value` line back out of a SOURCE.md.
source_field() {
  sed -n "s/^- $2:[[:space:]]*//p" "$1" | head -n1
}

TOTAL=0

if [ -n "$REPO_URL" ]; then
  # --- Explicit single source ------------------------------------------------
  slug="$(repo_slug "$REPO_URL")"
  [ -n "${NAME:-}" ] || NAME="${slug%%/*}"   # default name: the repo owner
  [ -n "$NAME" ] || fail "Could not derive a name from '$REPO_URL' — pass one explicitly."
  vendor_one "$REPO_URL" "$NAME" "$SUBDIR"
  sources=1
else
  # --- No args: refresh everything already vendored --------------------------
  [ -d "$VENDOR_DIR" ] || fail "No vendor/ directory yet — pass a repo URL (see $0 --help)."
  sources=0
  for d in "$VENDOR_DIR"/*/; do
    name="$(basename "$d")"
    [ -f "$d/SOURCE.md" ] || { warn "vendor/$name has no SOURCE.md — skipping."; continue; }
    url="$(source_field "$d/SOURCE.md" 'Repo')"
    dir="$(source_field "$d/SOURCE.md" 'Skills dir')"
    [ -n "$url" ] || { warn "vendor/$name/SOURCE.md has no Repo: line — skipping."; continue; }
    vendor_one "$url" "$name" "${dir:-$DEFAULT_SUBDIR}"
    sources=$((sources + 1))
  done
  [ "$sources" -gt 0 ] || fail "Nothing to refresh — pass a repo URL (see $0 --help)."
fi

# --- Done --------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Vendored $TOTAL skill(s) from $sources source(s)"
echo "============================================="
info "Next: run $ROOT/sync.sh to update the live dir."
