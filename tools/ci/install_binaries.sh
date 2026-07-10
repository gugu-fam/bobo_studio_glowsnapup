#!/usr/bin/env bash
set -euo pipefail

echo "CI: install or fetch required binaries (bspatch, spm_encode/spm_decode)"

DEST_DIR="$(pwd)/files/bin"
mkdir -p "$DEST_DIR"

# If CI provides an artifacts URL, download and extract
if [ -n "${BINARIES_ARTIFACT_URL-}" ]; then
  echo "Downloading binaries from BINARIES_ARTIFACT_URL"
  tmp="/tmp/ci_binaries.tar.gz"
  curl -fsSL "$BINARIES_ARTIFACT_URL" -o "$tmp"
  tar -xzf "$tmp" -C "$DEST_DIR"
  chmod +x "$DEST_DIR"/* || true
  echo "Binaries installed to $DEST_DIR"
  exit 0
fi

# Fallback: check PATH; if missing, warn and continue
missing=()
for b in bspatch spm_encode spm_decode; do
  if ! command -v "$b" >/dev/null 2>&1; then
    missing+=("$b")
  fi
done

if [ ${#missing[@]} -ne 0 ]; then
  echo "CI: missing binaries: ${missing[*]}"
  echo "If you want CI to provide binaries, set BINARIES_ARTIFACT_URL to a tar.gz containing bspatch and spm binaries."
  echo "Alternatively, add a build step to install system packages or include prebuilt binaries in the repository's files/ directory."
else
  echo "All required binaries present in PATH"
fi
