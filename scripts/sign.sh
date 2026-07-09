#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d)
ARCHIVE="archive/bobo_studio_glowsnapup-${TS}.tar.gz"
if [ ! -f "$ARCHIVE" ]; then
  echo "Archive not found: $ARCHIVE" >&2
  exit 1
fi
gpg --armor --output "${ARCHIVE}.asc" --detach-sign "$ARCHIVE"
sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"
echo "Signed $ARCHIVE"
