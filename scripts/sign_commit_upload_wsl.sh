#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

git add lib/features/product/photo_studio_service.dart test/features/product/photo_studio_service_test.dart
git commit -S -m "feat(photo): implement uploadPhoto in photo_studio_service with unit tests"
git log --oneline -3
git show --format=%G? -s HEAD
