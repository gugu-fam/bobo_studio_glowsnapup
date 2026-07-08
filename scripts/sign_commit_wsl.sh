#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

git reset --soft HEAD~1
git commit -S -m "feat(generate): add photo studio skeletons"
git log --oneline -1
git show --format=%G? -s HEAD
ls -l lib/features/product || true
