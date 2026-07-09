#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/gen_revoke.sh <KEYID> [output-dir]
KEYID="${1:-}"
OUTDIR="${2:-reports/key_management}"
if [ -z "$KEYID" ]; then
  echo "Usage: $0 <KEYID> [output-dir]" >&2
  exit 2
fi
mkdir -p "$OUTDIR"
OUTFILE="${OUTDIR}/revoke-${KEYID}-$(date +%Y%m%d_%H%M%S).asc"

echo "Generating revocation certificate for $KEYID -> $OUTFILE"
# This will prompt for confirmation; run on an offline machine interactively
gpg --output "$OUTFILE" --gen-revoke "$KEYID"

# Secure the file: set restrictive permissions
chmod 600 "$OUTFILE"
echo "Revocation certificate created and saved to $OUTFILE"
echo "IMPORTANT: Move $OUTFILE to offline secure storage (encrypt and store in multiple locations)."
