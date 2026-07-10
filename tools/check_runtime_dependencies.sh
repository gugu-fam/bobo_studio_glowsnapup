#!/usr/bin/env bash
set -euo pipefail

echo "Checking runtime dependencies..."

missing=()

check_bin(){
  if ! command -v "$1" >/dev/null 2>&1; then
    missing+=("$1")
  fi
}

check_bin bspatch || true
check_bin spm_encode || true
check_bin spm_decode || true

if [ ${#missing[@]} -ne 0 ]; then
  echo "Missing binaries: ${missing[*]}"
  echo "Possible fixes:"
  echo " - Install bspatch (bsdiff/bspatch) via package manager (e.g. apt install bsdiff) or include a bundled binary in files/" 
  echo " - Provide SentencePiece binaries (spm_encode/spm_decode) in PATH or set up JNI bindings"
  exit 0
fi

# Check for expected keys in repository files dir
PUBKEY_PATH="$(pwd)/app/src/main/assets/keys/model_signer_pub.pem"
if [ ! -f "$PUBKEY_PATH" ]; then
  echo "Warning: model signer public key not found at $PUBKEY_PATH"
  echo "Place the PEM at the path above for local runs, or configure CI to supply it via secrets/secure storage."
fi

# Java version check (Robolectric SDK 36 requires Java 21)
if command -v java >/dev/null 2>&1; then
  JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  # handle versions like 21, 17, or 1.8
  if [[ "$JAVA_VER" =~ ^1[.] ]]; then
    JAVA_MAJOR=$(echo "$JAVA_VER" | awk -F. '{print $2}')
  else
    JAVA_MAJOR=$JAVA_VER
  fi
  if [ "$JAVA_MAJOR" -lt 21 ]; then
    echo "Warning: Java major version $JAVA_MAJOR detected. Robolectric Android SDK 36 requires Java 21 to run tests reliably."
    echo "Install JDK 21 for running unit tests (locally) or let CI use JDK 21."
  fi
else
  echo "Warning: java not found in PATH; unit tests requiring Robolectric will not run locally."
fi

echo "Runtime dependency check complete."
