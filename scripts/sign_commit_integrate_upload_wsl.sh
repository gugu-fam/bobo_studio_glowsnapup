#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

git add lib/features/product/photo_studio_widget.dart test/features/product/photo_studio_widget_test.dart
git commit -S -m "feat(photo): call uploadPhoto from PhotoStudioWidget and add widget integration tests"
git log --oneline -3
git show --format=%G? -s HEAD
