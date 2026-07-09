#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/export_subkeys.sh <KEYID> [output-dir]
KEYID="${1:-}"
OUTDIR="${2:-reports/key_management}"
if [ -z "$KEYID" ]; then
  echo "Usage: $0 <KEYID> [output-dir]" >&2
  exit 2
fi
mkdir -p "$OUTDIR"
TMPFILE="${OUTDIR}/secret-subkeys-${KEYID}-$(date +%Y%m%d_%H%M%S).asc"
ENCFILE="${TMPFILE}.gpg"

echo "Exporting secret subkeys for $KEYID to $TMPFILE (will be encrypted to $ENCFILE)"
# Export secret subkeys only (not the primary secret key)
gpg --armor --export-secret-subkeys "$KEYID" > "$TMPFILE"

# Symmetric encrypt the exported file for safe transfer
gpg --symmetric --cipher-algo AES256 --output "$ENCFILE" "$TMPFILE"

# Wipe the plain export
shred -u "$TMPFILE" || rm -f "$TMPFILE"

chmod 600 "$ENCFILE"
echo "Secret subkeys exported and encrypted to $ENCFILE"
echo "Transfer $ENCFILE via secure channel and delete local copy if not needed."
