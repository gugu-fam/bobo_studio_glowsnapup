#!/usr/bin/env bash
# scripts/sign_commit.sh - wrapper for GPG-signed commits and audit logging
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"commit message\""
  exit 2
fi

MSG="$1"
git add -A
git commit -S -m "$MSG"
echo "Signed commit created"
mkdir -p audit/logs
ts=$(date -u +%Y%m%dT%H%M%SZ)
echo "{\"timestamp\": \"$ts\", \"action\": \"sign_commit\", \"message\": \"$MSG\"}" > audit/logs/audit_${ts}.json
echo "Audit log written to audit/logs/audit_${ts}.json"
