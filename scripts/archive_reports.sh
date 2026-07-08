#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

TS=$(date -u +"%Y%m%dT%H%M%SZ")
ARCHIVE_DIR=reports/archive
mkdir -p "$ARCHIVE_DIR"

# Backup reports directory (non-destructive)
BACKUP_DIR="reports.bak.$TS"
cp -a reports "$BACKUP_DIR"

# Build include list
include=()
for pattern in "reports/SIGNATURE_VERIFICATION.md" "reports/public_gpg_*.asc" "reports/validated_design.json" "reports/tree.json" "reports/*.log" "reports/*.json" "reports/*.txt"; do
  for f in $(sh -c "ls $pattern 2>/dev/null || true"); do
    case "$f" in
      "$ARCHIVE_DIR"* ) continue ;;
    esac
    include+=("$f")
  done
done

if [ ${#include[@]} -eq 0 ]; then
  echo "No files found to archive. Exiting." >&2
  exit 1
fi

ARCHIVE="$ARCHIVE_DIR/reports-${TS}.tar.gz"
printf "%s\n" "Creating archive $ARCHIVE with files:" "${include[@]}"
tar -czf "$ARCHIVE" "${include[@]}"

# Sign archive with GPG (detached, armored)
gpg --armor --output "${ARCHIVE}.asc" --detach-sign "$ARCHIVE"

# Create sha256
sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"

# Update ARCHIVE_INDEX.md
INDEX=reports/ARCHIVE_INDEX.md
cat >> "$INDEX" <<EOF
- archive: ${ARCHIVE}
  signature: ${ARCHIVE}.asc
  sha256: ${ARCHIVE}.sha256
  created_at: ${TS}
  created_by: $(git config user.name || echo unknown)
  gpg_key_shortid: $(gpg --list-secret-keys --keyid-format=long | awk '/^sec/ {print $2; exit}' | awk -F'/' '{print $2}')
EOF

# Commit archive and index (signed commit)
git add "$ARCHIVE" "${ARCHIVE}.asc" "${ARCHIVE}.sha256" "$INDEX"
if git commit -m "chore(reports): add audit archive ${ARCHIVE}" -S; then
  COMMIT_STATUS="signed"
else
  git commit -m "chore(reports): add audit archive ${ARCHIVE} (unsigned: signing failed)"
  COMMIT_STATUS="unsigned"
fi

ls -l "$ARCHIVE_DIR"
echo "--- git last commit ---"
git log --oneline -1
echo "BACKUP_DIR=$BACKUP_DIR"
echo "COMMIT_STATUS=$COMMIT_STATUS"
