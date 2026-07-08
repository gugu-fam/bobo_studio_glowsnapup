[AUTO-GEN][Sprint1] PhotoStudio minimal impl + tests + verification reports

## Summary
- Minimal PhotoStudio implementation added.
- Unit and widget tests included (see `test/widget_test.dart`).
- Generated verification reports added under `reports/`:
  - `dart_analyze_top_warnings.txt`
  - `flutter_test_report_utf8.json`
  - `photo_studio_test_report_utf8.json`
  - `responsibility_report.json`
  - `skeletons_dry_run_report.json`
  - `viewmodel_analyze.txt` / `viewmodel_analyze_utf8.txt`

## What changed
- New files: `pubspec.lock`, `test/`, `tools/`, `reports/`, `web/`, `windows/` assets and runner files.
- Minor fixes and test scaffolding to enable CI verification.

## Notes and follow-ups
- **Commit signatures:** latest commit `d383e8d...` shows `signature: NONE`.
- **Logger change:** separate branch `fix/logger-debugprint` contains replacement of `print` with `debugPrint`. That fix is being cherry-picked from main into a new branch for a focused PR.
- **Security:** verify `reports/` and any `audit/logs` do not contain sensitive data before merging.
- **CI:** expect `dart analyze` and `flutter test` to run; artifacts under `reports/` should be uploaded by CI.

## How to review
1. Run `flutter pub get` then `dart analyze`.
2. Run `flutter test` and inspect `reports/flutter_test_report_utf8.json`.
3. Check platform-specific runner files under `windows/` only for binary or generated content.

## Acceptance criteria
- All CI checks pass (analyze + tests).
- No secrets or sensitive logs in `reports/`.
- Logger fix PR merged or approved separately.
