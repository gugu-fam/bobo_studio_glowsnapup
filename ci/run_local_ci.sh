#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== deps ==="
flutter pub get

echo "=== analyze ==="
dart analyze

echo "=== unit tests ==="
flutter test test/features/product/photo_studio_service_test.dart

echo "=== widget tests ==="
flutter test test/features/product/photo_studio_widget_test.dart

echo "=== generate reports ==="
mkdir -p reports
flutter test --reporter=json > reports/flutter_test.json || true

echo "=== archive ==="
TS=$(date +%Y%m%d)
mkdir -p archive
git archive --format=tar --prefix=bobo_studio_glowsnapup/ HEAD | gzip > archive/bobo_studio_glowsnapup-${TS}.tar.gz
sha256sum archive/bobo_studio_glowsnapup-${TS}.tar.gz > archive/bobo_studio_glowsnapup-${TS}.tar.gz.sha256
gpg --armor --output archive/bobo_studio_glowsnapup-${TS}.tar.gz.asc --detach-sign archive/bobo_studio_glowsnapup-${TS}.tar.gz || true

echo "Local CI finished. Reports in reports/, archive in archive/"
