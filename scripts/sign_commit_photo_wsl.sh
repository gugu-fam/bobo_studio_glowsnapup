#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

git commit -S -m "feat(photo): integrate PhotoEditor into widget, add service stubs and tests"
git log --oneline -3
git show --format=%G? -s HEAD
