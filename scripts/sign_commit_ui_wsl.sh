#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

git commit -S -m "feat(ui): implement PhotoEditor widget"
git log --oneline -1
git show --format=%G? -s HEAD
