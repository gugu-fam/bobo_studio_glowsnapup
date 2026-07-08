#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

# find latest archive
ARCHIVE_FILE=$(ls -1 reports/archive/reports-*.tar.gz 2>/dev/null | sort | tail -n1)
if [ -z "$ARCHIVE_FILE" ]; then
  echo "No archive found in reports/archive" >&2
  exit 1
fi

ARCHIVE_BASENAME=$(basename "$ARCHIVE_FILE")
TS=$(echo "$ARCHIVE_BASENAME" | sed -E 's/reports-([0-9TZ]+)\.tar\.gz/\1/')

cat >> reports/ARCHIVE_INDEX.md <<EOF
- archive: reports/archive/${ARCHIVE_BASENAME}
  signature: reports/archive/${ARCHIVE_BASENAME}.asc
  sha256: reports/archive/${ARCHIVE_BASENAME}.sha256
  created_at: ${TS}
  created_by: $(git config user.name || echo unknown)
  gpg_key_shortid: 079F1148E9F2C635
  contents: SIGNATURE_VERIFICATION.md; public_gpg_079F1148E9F2C635.asc; dry_run_report.json; generate_report.json
EOF

git add reports/ARCHIVE_INDEX.md reports/archive/${ARCHIVE_BASENAME} reports/archive/${ARCHIVE_BASENAME}.asc reports/archive/${ARCHIVE_BASENAME}.sha256 || true

# Commit signed (use WSL GPG)
if git commit -m "chore(reports): update ARCHIVE_INDEX with latest audit archive ${ARCHIVE_BASENAME}" -S; then
  echo "SIGNED_COMMIT=1"
else
  echo "SIGNED_COMMIT=0"
fi

git log --oneline -1
echo "--- ARCHIVE_INDEX.md ---"
cat reports/ARCHIVE_INDEX.md
