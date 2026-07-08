#!/bin/bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

echo "PWD: $(pwd)"

echo "--- GPG secret keys (list) ---"
gpg --list-secret-keys --keyid-format=long || true

KEYID=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1=="sec" {print $5; exit}')
if [ -z "$KEYID" ]; then
  echo "ERROR: no secret GPG key found in WSL user. Please generate a key first."
  exit 2
fi

echo "Using GPG KEYID: $KEYID"

# Configure git to use this signing key locally
git config user.signingkey "$KEYID"
git config gpg.program gpg

SHA=$(git rev-parse HEAD)
TAG="signed/audit-$(date -u +%Y%m%dT%H%M%SZ)"

echo "Creating signed tag $TAG -> $SHA"
git tag -s "$TAG" -m "Audit-signed tag for ${SHA}" "$SHA"

echo "Verifying tag signature:"
git tag -v "$TAG" || true

mkdir -p reports
PUBFILE=reports/public_gpg_${KEYID}.asc
gpg --armor --export "$KEYID" > "$PUBFILE"
echo "Exported public key to $PUBFILE"

echo "$TAG"
