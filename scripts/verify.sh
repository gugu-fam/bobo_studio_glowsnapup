#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d)
ARCHIVE="archive/bobo_studio_glowsnapup-${TS}.tar.gz"
if [ ! -f "$ARCHIVE" ]; then
  echo "Archive not found: $ARCHIVE" >&2
  exit 1
fi
gpg --verify "${ARCHIVE}.asc" "$ARCHIVE"
sha256sum -c "${ARCHIVE}.sha256"
echo "Verification OK"
