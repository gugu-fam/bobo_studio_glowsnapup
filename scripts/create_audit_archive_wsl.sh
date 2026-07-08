#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/flutter_projects/bobo_studio_glowsnapup"
cd "$REPO"

# 1. ensure latest commit recorded (non-fatal)
git add -A
git commit -m "chore(audit): prepare archive for upload integration" || true

# 2. create archive
TS=$(date +%Y%m%d)
mkdir -p archive
git archive --format=tar --prefix=bobo_studio_glowsnapup/ HEAD | gzip > archive/bobo_studio_glowsnapup-${TS}.tar.gz

# 3. sha256
sha256sum archive/bobo_studio_glowsnapup-${TS}.tar.gz > archive/bobo_studio_glowsnapup-${TS}.tar.gz.sha256

# 4. gpg sign (ASCII detached)
gpg --armor --output archive/bobo_studio_glowsnapup-${TS}.tar.gz.asc --detach-sign archive/bobo_studio_glowsnapup-${TS}.tar.gz

# 5. archive reports bundle (optional)
tar -czf archive/reports-${TS}.tar.gz reports/ || true
gpg --armor --output archive/reports-${TS}.tar.gz.asc --detach-sign archive/reports-${TS}.tar.gz || true

# 6. append to reports/ARCHIVE_INDEX.md
IDX=reports/ARCHIVE_INDEX.md
mkdir -p reports
touch "$IDX"
SHA=$(sha256sum archive/bobo_studio_glowsnapup-${TS}.tar.gz | awk '{print $1}')
COMMIT=$(git rev-parse --short HEAD)
cat >> "$IDX" <<EOF

## ${TS} — feat: integrate upload into PhotoStudioWidget
- Commit: ${COMMIT}
- Summary: Integrated uploadPhoto into PhotoStudioWidget; added service upload and widget integration tests.
- Archive: archive/bobo_studio_glowsnapup-${TS}.tar.gz
- SHA256: ${SHA}
- Signature: archive/bobo_studio_glowsnapup-${TS}.tar.gz.asc
- Reports: archive/reports-${TS}.tar.gz (signed: archive/reports-${TS}.tar.gz.asc)
EOF

# 7. list archive
ls -l archive

echo "WROTE_ARCHIVE=$TS"
