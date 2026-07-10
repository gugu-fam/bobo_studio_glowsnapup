#!/usr/bin/env bash
# ci/validate_and_generate_local.sh - local CI runner skeleton
set -euo pipefail

echo "1. Validating design schemas..."
# TODO: run schema validation (yamllint / custom schema)

echo "2. Generating tests (dry-run -> apply)..."
python3 tools/generate_tests.py --dry-run
python3 tools/generate_tests.py

echo "3. Gradle lint & tests (invoke gradlew)..."
./gradlew lint test jacocoTestReport || true

echo "4. Static analysis (semgrep)..."
# semgrep --config ...

echo "5. Coverage check..."
# python3 validators/coverage_check.py

echo "Local CI skeleton complete"
