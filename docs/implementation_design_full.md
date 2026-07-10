# 実装フェーズ設計（フルパッケージ）

この文書は「bobo-Studio-GlowSnapup」プロジェクトの実装フェーズに必要な設計を、コードを書く直前の粒度まで言語化したものです。
リポジトリ内への反映物（ファイル・スケルトン）の一覧と各ファイルに書くべき内容を明確に示します。

## 目的
- 設計フェーズ（100%完了）をリポジトリに明確に反映し、実装チームが即コードを書き始められる状態とする。

## 反映対象（ファイル一覧）
- `app/src/main/cpp/native_loader.cpp` : 暗号化モデルのチャンク復号・匿名mmap・ハンドル管理のネイティブ実装（スケルトン）
- `app/src/main/java/com/bobo/glowsnapup/native/NativeLoader.kt` : JNI ラッパー
- `app/src/main/java/com/bobo/glowsnapup/services/CameraService.kt` : CameraX ラッパー
- `app/src/main/java/com/bobo/glowsnapup/services/ModelManager.kt` : モデル管理（import/list/delete/applyDelta）
- `app/src/main/java/com/bobo/glowsnapup/services/InferenceService.kt` : TFLite 推論ラッパー
- `app/src/main/java/com/bobo/glowsnapup/services/CryptoService.kt` : Keystore/AES-GCM 管理
- `app/src/main/java/com/bobo/glowsnapup/services/TranslationService.kt` : SentencePiece + TFLite 翻訳
- `app/src/main/java/com/bobo/glowsnapup/services/DiagService.kt` : 診断・監査ログ管理
- `app/src/main/java/com/bobo/glowsnapup/services/ThermalGuard.kt` : サーマル保護
- `tools/generate_tests.py` : design/*.yaml → Kotlin/JUnit テスト自動生成スクリプト（スケルトン）
- `tools/auto_bench_inference.sh` : 推論ベンチスクリプト（スケルトン）
- `tools/run_endurance_test.sh` : 耐久テストスクリプト（スケルトン）
- `ci/validate_and_generate_local.sh` : ローカルCI相当の統合スクリプト（スケルトン）
- `scripts/sign_commit.sh` : 署名付きコミットのラッパースクリプト
- `docs/implementation_checklist.md` : 作業抜け漏れチェックリスト
- `docs/implementation_completion_report.md` : 完了報告書（雛形）
- `tests/generated/.placeholder` : 生成テストディレクトリプレースホルダ

## ファイル毎の詳細（実装指示）

### native_loader.cpp
- AES-GCM 復号のストリーミング処理。チャンクは `IV(12) || CIPHERTEXT || TAG(16)` を想定。
- 復号結果を匿名 `mmap` にコピーし、`mprotect(PROT_READ)` を適用。
- ハンドル管理を行い、Java 側は `long handle` を受け取り `ByteBuffer` を取得する。
- エラーは JNI 経由で例外に変換する。

### NativeLoader.kt
- `external` メソッドでネイティブ呼び出しをラップ。
- 呼び出しに対して Kotlin 例外でラップするユーティリティを提供。

### CameraService.kt
- CameraX の初期化・権限チェック・プレビュー接続・解析フレームコールバックを実装。
- サーマル状態に応じた解析 frequency 制御を `ThermalGuard` から参照。

### ModelManager.kt
- import: マジックナンバー検査、SHA256 計算、CryptoService で AES-GCM 暗号化、`files/models/{name}/{version}/` に保存。
- list/delete: `meta.json` を読み書きしてメタ管理。
- applyDeltaUpdate: 署名検証 → bsdiff 適用 → SHA256 確認。

### InferenceService.kt
- `loadModel(buffer: ByteBuffer)` で TFLite Interpreter を初期化。
- `runOnFrame` / `runOnTiles` は `PrePostProcessor` を利用して前処理・後処理を実施。
- delegate 切替（NNAPI/GPU/CPU）と threads/tileSize のランタイム調整。

### CryptoService.kt
- Keystore（StrongBox 優先）で AES キーを生成・保護。バックアップ鍵は PBKDF2 で派生。
- `encryptModel` は AES-GCM によりチャンク化して保存するユーティリティを提供。

### TranslationService.kt
- SentencePiece トークナイザとのインターフェースを提供。
- small TFLite 翻訳モデルのロード・推論パスを実装。

### DiagService.kt
- 診断イベントを暗号化して `files/diag/` に保存。ユーザー許可によりエクスポート可能。

### ThermalGuard.kt
- OS サーマル API から状態を取得し、推論/解析の throttle 値を計算して返す。

## CI / tools / scripts 指示
- `tools/generate_tests.py` は YAML 構造解析 → Kotlin/JUnit テンプレートを生成。`--dry-run` と `--apply` を実装。
- `ci/validate_and_generate_local.sh` は schema validation → generate_tests（dry-run→apply）→ `./gradlew lint test jacocoTestReport` → `semgrep` → `validators/coverage_check.py` を順に実行。
- `scripts/sign_commit.sh` は `git commit -S -m` を呼び出し、成功時に `audit/logs` へ記録。

## テスト・ベンチ指示
- `tools/auto_bench_inference.sh` は delegate/threads/tileSize の組合せでベンチを取り、`bench_results.json` を生成して `InferenceConfig` に反映する。
- `tools/run_endurance_test.sh` は 10/30/60 分モードを実装し、`endurance_report.json` を保存。

## 監査・署名・ロールバック
- `audit/logs/` に `audit_{ts}.json` を残す。署名付き差分適用ならば `signature` を必須フィールドとして検証する。

## 実装チェックリスト（自動反映用）
- docs/implementation_checklist.md を更新して、各モジュールごとの検証項目を列挙する。

## 次のアクション
1. 本ドキュメントをリポジトリに追加（本ファイル） — 完了
2. スケルトンファイルを追加 — 継続
3. CI / tools スクリプトのスケルトン追加 — 継続
4. 最終チェックと完了報告書の作成 — 継続

---
注: この文書は実装の青写真です。実装時には各ファイルの TODO コメントに沿って実装を進めてください。
