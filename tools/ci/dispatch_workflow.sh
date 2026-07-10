#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_FILE="ci.yml"
REF_BRANCH="handover/GitHub-Copilot"
REPO="${GITHUB_REPOSITORY:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. To dispatch the CI workflow from your machine, install GitHub CLI and run:"
  echo "  gh workflow run $WORKFLOW_FILE --ref $REF_BRANCH --repo <owner>/<repo>"
  exit 0
fi

if [ -z "$REPO" ]; then
  # try to detect from git
  REPO=$(git config --get remote.origin.url || true)
  if [ -n "$REPO" ]; then
    # convert to owner/repo if possible
    REPO=$(echo "$REPO" | sed -E 's#.*[:/](.+/.+)(\.git)?$#\1#')
  fi
fi

if [ -z "$REPO" ]; then
  echo "Unable to determine repository. Set GITHUB_REPOSITORY env or run gh manually."
  exit 1
fi

echo "Dispatching workflow $WORKFLOW_FILE on ref $REF_BRANCH in $REPO"
gh workflow run "$WORKFLOW_FILE" --ref "$REF_BRANCH" --repo "$REPO"
echo "Dispatched. Check GitHub Actions UI for progress."
