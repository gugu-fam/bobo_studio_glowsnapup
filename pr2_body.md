## 概要
logger の出力を lint に合わせて print から debugPrint に変更しました。
依存を元の pubspec.yaml から安全にマージし、最小のプレースホルダテストを追加しました。

## 動作確認（ローカル）
- flutter pub get: OK
- dart analyze: No issues found
- flutter test: All tests passed

## 注意点
- 元の pubspec.yaml は pubspec.yaml.postmerge.bak に保存しています。必要なら差分を確認して調整してください。
- CI の SDK バージョンと合わせる必要がある場合は environment.sdk を調整してください。
