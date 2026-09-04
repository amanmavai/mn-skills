#!/usr/bin/env bash
# branch-info.sh - Minimal branch context
# Usage: branch-info.sh [base-branch]

set -euo pipefail

BASE_BRANCH=${1:-main}

git fetch origin >/dev/null 2>&1 || true;

if ! git rev-parse --verify "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
    echo "Error: Base branch 'origin/${BASE_BRANCH}' not found" >&2
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_COUNT=$(git rev-list --count "origin/${BASE_BRANCH}..HEAD" 2>/dev/null || echo 0)

echo "=== Branch Context ==="
echo "Branch: ${CURRENT_BRANCH} -> origin/${BASE_BRANCH}"
echo "Commit count: $COMMIT_COUNT"
echo ""

echo "=== Commit Log ==="
LOG_OUTPUT=$(git --no-pager log --oneline "origin/${BASE_BRANCH}..HEAD" 2>/dev/null || true)
if [ -z "$LOG_OUTPUT" ]; then
  echo "No commits"
else
  echo "$LOG_OUTPUT"
fi
echo ""

echo "=== Sorted Churn Stats ==="
NUMSTAT_OUTPUT=$(git --no-pager diff "origin/${BASE_BRANCH}...HEAD" --numstat 2>/dev/null || true);

if [ -z "$NUMSTAT_OUTPUT" ]; then
  echo "No changes"
else
  echo $'Churn\tAdded\tDeleted\tFile'
  printf "%s\n" "${NUMSTAT_OUTPUT}" \
    | awk -F'\t' 'BEGIN { OFS="\t" } {
        a = ($1 == "-") ? 0 : $1
        d = ($2 == "-") ? 0 : $2
        print a + d, a, d, $3
    }' \
    | sort -nr -k1,1
fi
echo ""

echo "=== New Files ==="
NEW_FILES=$(git --no-pager diff "origin/${BASE_BRANCH}...HEAD" --diff-filter=A --name-only 2>/dev/null || true)
if [ -z "$NEW_FILES" ]; then
  echo "No new files"
else
  echo "$NEW_FILES"
fi
echo ""

echo "=== Diff Stats ==="
DIFF_STATS=$(git --no-pager diff "origin/${BASE_BRANCH}...HEAD" --shortstat 2>/dev/null || true)
if [ -z "$DIFF_STATS" ]; then
  echo "No changes"
else
  echo "$DIFF_STATS"
fi
echo ""
