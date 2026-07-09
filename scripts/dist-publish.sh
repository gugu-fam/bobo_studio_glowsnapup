#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/dist-publish.sh /path/to/destination [--scp user@host:/path] [--yes]
# If --scp is provided, destination is ignored and scp is used.

DIST_DIR=dist
LOGDIR=reports/publish_logs
mkdir -p "$LOGDIR"
# rotate keep last 30 logs
find "$LOGDIR" -type f -name 'dist-publish-*.log' -printf '%T@ %p\n' | sort -n | awk '{print $2}' | head -n -30 | xargs -r rm -f || true
LOGFILE="$LOGDIR/dist-publish-$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=false
FORCE=false
SCP_TARGET=""

# parse args
DEST="${1-}"
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --scp)
      SCP_TARGET="$2"
      shift 2
      ;;
    --yes)
      FORCE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if [ ! -d "$DIST_DIR" ]; then
  echo "Error: dist directory not found: $DIST_DIR" | tee "$LOGFILE"
  exit 1
fi

# pick latest archive
ARCHIVE_FILE=$(ls -1t ${DIST_DIR}/bobo_studio_glowsnapup-*.tar.gz 2>/dev/null | head -n1 || true)
if [ -z "$ARCHIVE_FILE" ]; then
  echo "No archive found in $DIST_DIR" | tee "$LOGFILE"
  exit 1
fi
ASC_FILE="${ARCHIVE_FILE}.asc"
SHA_FILE="${ARCHIVE_FILE}.sha256"

echo "Selected archive: $ARCHIVE_FILE" | tee "$LOGFILE"

# verify before publish
echo "Verifying SHA256..." | tee -a "$LOGFILE"
if ! sha256sum -c "$SHA_FILE" >> "$LOGFILE" 2>&1; then
  echo "SHA256 verification failed. Aborting." | tee -a "$LOGFILE"
  exit 1
fi

echo "Verifying GPG signature..." | tee -a "$LOGFILE"
if ! gpg --verify "$ASC_FILE" "$ARCHIVE_FILE" >> "$LOGFILE" 2>&1; then
  echo "GPG verification failed. Aborting." | tee -a "$LOGFILE"
  exit 1
fi

# prepare destination
if [ -n "$SCP_TARGET" ]; then
  echo "Publishing via scp to $SCP_TARGET" | tee -a "$LOGFILE"
  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: scp $ARCHIVE_FILE $ASC_FILE $SHA_FILE $SCP_TARGET" | tee -a "$LOGFILE"
    exit 0
  fi
  scp "$ARCHIVE_FILE" "$ASC_FILE" "$SHA_FILE" "$SCP_TARGET" | tee -a "$LOGFILE"
  echo "scp finished" | tee -a "$LOGFILE"
else
  if [ -z "$DEST" ]; then
    echo "No destination provided. Usage: $0 /path/to/dest [--scp user@host:/path] [--yes]" | tee -a "$LOGFILE"
    exit 2
  fi
  mkdir -p "$DEST"
  TARGET_ARCHIVE="$DEST/$(basename "$ARCHIVE_FILE")"
  if [ -f "$TARGET_ARCHIVE" ] && [ "$FORCE" = false ]; then
    echo "Target file exists: $TARGET_ARCHIVE. Use --yes to overwrite." | tee -a "$LOGFILE"
    exit 3
  fi
  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: cp $ARCHIVE_FILE $ASC_FILE $SHA_FILE $DEST" | tee -a "$LOGFILE"
    exit 0
  fi
  cp -p "$ARCHIVE_FILE" "$DEST/"
  cp -p "$ASC_FILE" "$DEST/" 2>/dev/null || true
  cp -p "$SHA_FILE" "$DEST/" 2>/dev/null || true
  # copy public key and verification logs if present
  cp -p dist/public_gpg_*.asc "$DEST/" 2>/dev/null || true
  cp -p dist/gpg_verify_*.txt "$DEST/" 2>/dev/null || true
  cp -p dist/sha256_*.txt "$DEST/" 2>/dev/null || true
  # include VERIFY for receiver
  cp -p dist/VERIFY.md "$DEST/" 2>/dev/null || true
  echo "Files copied to $DEST" | tee -a "$LOGFILE"
fi

echo "Publish completed. Log: $LOGFILE" | tee -a "$LOGFILE"
