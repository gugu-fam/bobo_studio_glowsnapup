#!/usr/bin/env bash
set -euo pipefail

COUNT=${1-20}
echo "Verifying last $COUNT commits for GPG signatures..."
bad=()
for c in $(git rev-list --max-count=$COUNT HEAD); do
  if git verify-commit --verbose $c >/dev/null 2>&1; then
    echo "OK  $c"
  else
    echo "BAD $c"
    bad+=("$c")
  fi
done
if [ ${#bad[@]} -ne 0 ]; then
  echo "Found ${#bad[@]} unsigned or bad-signed commits"
  echo "You can add approved commit SHAs to .github/unsigned_allowlist.txt to document exceptions."
  printf "%s\n" "${bad[@]}" > /tmp/unsigned_commits.txt
  exit 1
fi
echo "All checked commits are signed"
