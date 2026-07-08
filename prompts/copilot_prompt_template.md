# Copilot Prompt Template — Skeleton Generation (Japanese)

目的: 指定の `design/validated_design.json` に従い、フォルダ単位で骨格コードを生成します。

制約:
- 既存ファイルは差分追加のみ。破壊的変更禁止。
- 生成はフォルダ単位で行う。
- 生成ファイルには必ず保存パスを明記する（先頭コメントに）。

出力:
- ファイルツリー JSON と各ファイルの骨格コード（ファイル先頭に保存パスコメントを挿入）。

必須検査:
- 型チェック通過（`dart analyze`）
- 未実装メソッド一覧を `integrity_report.json` に出力
- 生成ファイルに保存パスを明記

コミットメッセージ規約:
```
[AUTO-GEN][agent:<agent_id>][phase:<phase>] <short description>
Body:
- design_ref: path/to/design.yaml
- tree_ref: tree.json
- dry_run: true|false
- validation: PASS|FAIL
```
