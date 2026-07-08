## 概要
logger の出力を `print` から `debugPrint` に置き換える修正を適用しました。これによりデバッグログが適切に抑制され、`avoid_print` 等の lint 要求に整合します。

## 変更点
- `lib/core/logger.dart`: コンソール出力を `debugPrint` に変更
- 同ファイルに説明コメントを追加（lint/レビュー補助）

## 動作確認
- `dart analyze`: 問題なし（No issues found）
- `flutter test`: この環境ではテスト実行に必要なローカルのテストファイルが存在しない、または `flutter pub get` でプロジェクトルート検出に失敗したため未実行です。CI またはローカル環境で以下を実行してください：
  - `flutter pub get`
  - `flutter test`

## 影響範囲
- ログ出力動作の調整のみ。破壊的変更はありません。

## チェックリスト
- [x] `print` を `debugPrint` に置換
- [x] `dart analyze` を実行し問題なしを確認
- [ ] `flutter test` を CI/ローカルで通す

## 備考
関連: N/A
