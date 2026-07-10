#!/usr/bin/env bash
set -euo pipefail

OUTDIR="reports"
mkdir -p "$OUTDIR"
COUNT=${1-50}
TMP=/tmp/unsigned_commits.txt

echo "Scanning last $COUNT commits for unsigned/bad-signed entries..."
./scripts/list_unsigned_commits.sh "$COUNT" || true
if [ ! -f "$TMP" ]; then
  echo "No unsigned commits found. Writing empty report."
  echo "# Unsigned commits report\n\nNo unsigned commits found in the last $COUNT commits." > "$OUTDIR/unsigned_commits_report.md"
  exit 0
fi

REPORT="$OUTDIR/unsigned_commits_report.md"
echo "# Unsigned commits report" > "$REPORT"
echo "Scanned last $COUNT commits." >> "$REPORT"
echo >> "$REPORT"
echo "The following commits were reported as unsigned or bad-signed:" >> "$REPORT"
echo >> "$REPORT"
while read -r sha; do
  git show --no-patch --format='%h %an %ad %s' "$sha" >> "$REPORT" 2>/dev/null || echo "$sha (meta not available)" >> "$REPORT"
  echo >> "$REPORT"
done < "$TMP"

echo "Report written to $REPORT"

if command -v gh >/dev/null 2>&1; then
  if [ "${CREATE_PR-}" = "1" ]; then
    BRANCH="unsigned-report-$(date +%s)"
    git checkout -b "$BRANCH"
    git add "$REPORT"
    git commit -m "chore: add unsigned commits report"
    git push --set-upstream origin "$BRANCH"
    gh pr create --title "Unsigned commits report" --body-file "$REPORT" --draft
    echo "Created PR with report"
  fi
fi
