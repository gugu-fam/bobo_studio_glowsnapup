#!/usr/bin/env bash
set -euo pipefail

# 設定
TS=$(date +%Y%m%d)
ARCHIVE_DIR=archive
DIST_DIR=dist
REPORTS_DIR=reports
KEYID=34E99ECD52FE1A446FC8CFB2079F1148E9F2C635

# 前提チェック
if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "Archive directory not found: $ARCHIVE_DIR" >&2
  exit 1
fi
mkdir -p "$DIST_DIR"

# 対象ファイルを選ぶ（最新のタイムスタンプを優先）
ARCHIVE_FILE=$(ls -1t ${ARCHIVE_DIR}/bobo_studio_glowsnapup-*.tar.gz | head -n1 || true)
if [ -z "$ARCHIVE_FILE" ]; then
  echo "No archive found in ${ARCHIVE_DIR}" >&2
  exit 1
fi
ASC_FILE="${ARCHIVE_FILE}.asc"
SHA_FILE="${ARCHIVE_FILE}.sha256"

# 検証（念のため再検証）
echo "Verifying SHA256 and GPG for $ARCHIVE_FILE"
if [ -f "$SHA_FILE" ]; then
  sha256sum -c "$SHA_FILE"
else
  echo "Warning: SHA file not found: $SHA_FILE" >&2
fi

if [ -f "$ASC_FILE" ]; then
  gpg --verify "$ASC_FILE" "$ARCHIVE_FILE"
else
  echo "Warning: asc signature not found: $ASC_FILE" >&2
fi

# コピー
cp "$ARCHIVE_FILE" "$DIST_DIR/"
cp "$ASC_FILE" "$DIST_DIR/" 2>/dev/null || true
cp "$SHA_FILE" "$DIST_DIR/" 2>/dev/null || true

# 公開鍵と検証ログを同梱
if [ -f "${REPORTS_DIR}/public_gpg_${KEYID}.asc" ]; then
  cp "${REPORTS_DIR}/public_gpg_${KEYID}.asc" "$DIST_DIR/"
else
  # 生成して同梱（失敗しても続行）
  gpg --armor --output "${DIST_DIR}/public_gpg_${KEYID}.asc" --export "$KEYID" || true
fi

# 検証ログをコピー（あれば）
cp ${REPORTS_DIR}/gpg_verify_*.txt "${DIST_DIR}/" 2>/dev/null || true
cp ${REPORTS_DIR}/sha256_*.txt "${DIST_DIR}/" 2>/dev/null || true

## copy VERIFY.md if present
if [ -f "VERIFY.md" ]; then
  cp VERIFY.md "$DIST_DIR/" || true
fi

# パーミッションと一覧
chmod -R 640 "$DIST_DIR" || true
echo "Dist prepared in $DIST_DIR:"
ls -l "$DIST_DIR"
