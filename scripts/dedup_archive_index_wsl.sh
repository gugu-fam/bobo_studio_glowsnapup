#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

TS=$(date -u +"%Y%m%dT%H%M%SZ")
cp reports/ARCHIVE_INDEX.md reports/ARCHIVE_INDEX.md.bak."$TS"

# Deduplicate blocks (blocks separated by blank lines), keep first occurrence
awk 'BEGIN{RS=""; ORS="\n\n"} !seen[$0]++{print $0}' reports/ARCHIVE_INDEX.md > reports/ARCHIVE_INDEX.md.tmp
mv reports/ARCHIVE_INDEX.md.tmp reports/ARCHIVE_INDEX.md

echo "--- diff (ARCHIVE_INDEX.md) ---"
git --no-pager diff -- reports/ARCHIVE_INDEX.md || true

git add reports/ARCHIVE_INDEX.md
if git commit -m "chore(reports): deduplicate ARCHIVE_INDEX entries" -S; then
  echo "SIGNED_COMMIT=1"
else
  echo "SIGNED_COMMIT=0"
fi

git log --oneline -1
echo "--- ARCHIVE_INDEX.md content ---"
cat reports/ARCHIVE_INDEX.md
