#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="$(pwd)/app/src/main/assets/keys"
mkdir -p "$DEST_DIR"

if [ -n "${MODEL_SIGNER_PEM_B64-}" ]; then
  echo "$MODEL_SIGNER_PEM_B64" | base64 --decode > "$DEST_DIR/model_signer_pub.pem"
  echo "Wrote model_signer_pub.pem from MODEL_SIGNER_PEM_B64"
elif [ -n "${MODEL_SIGNER_PEM_PATH-}" ] && [ -f "$MODEL_SIGNER_PEM_PATH" ]; then
  cp "$MODEL_SIGNER_PEM_PATH" "$DEST_DIR/model_signer_pub.pem"
  echo "Copied model_signer_pub.pem from MODEL_SIGNER_PEM_PATH"
else
  echo "No MODEL_SIGNER_PEM_B64 or MODEL_SIGNER_PEM_PATH provided; skipping"
fi
