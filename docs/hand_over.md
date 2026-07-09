---

### プロジェクト概要・目的・大前提・絶対厳守事項

```markdown
# プロジェクト概要 目的 大前提 絶対厳守事項

## プロジェクト概要
**bobo‑Studio‑GlowSnapup** は、スマートフォンで撮影した商品写真を「スタジオ撮影風」に自動で補正・背景処理し、出品用の説明文や翻訳をオンデバイスで生成するアプリケーションです。外部クラウド依存を排し、**オンデバイス推論とローカル運用**を基本とします。

## 目的
- **ユーザー価値**: 出品者が短時間で高品質な商品写真と説明文を作成できるようにする。  
- **技術目標**: オンデバイス推論で**低レイテンシ（small モデル中央値 ≤ 800 ms）**を達成し、モデルとデータを安全に管理する。  
- **運用目標**: ローカルで完結する自動生成ワークフローと監査ログを備え、配布と更新を安全に行う。

## 大前提
- **外部クラウドサービスは使用しない**（ユーザーが任意で外部APIキーを提供する場合は別）。  
- **すべての機密鍵は Android Keystore（StrongBox 優先）で管理**。鍵素材を平文で保存・転送しない。  
- **モデルは暗号化して保存**し、復号はメモリ上で行う。平文をディスクに残さない。  
- **ユーザーデータは端末内に留める**。外部送信はユーザーの明示的同意がある場合のみ。

## 絶対厳守事項
1. **鍵素材の保護**: Keystore から直接エクスポートした鍵バイト列を永続化してはならない。  
2. **平文の不保存**: 復号したモデルや中間平文をディスクに書き出してはならない。  
3. **段階的セキュリティ対応**: アンチ解析や改変検出は段階的に実施し、誤検出でユーザー体験を損なわないこと。  
4. **自動生成ワークフローの署名**: 自動生成物は必ず署名付きコミットで管理する。  
5. **テストカバレッジ閾値**: 重要モジュールは 80% 以上のカバレッジを維持する。  
6. **差分更新の署名検証**: 差分適用前に署名検証を必須とする。  
7. **ユーザー通知**: セキュリティやプライバシーに関わる変更はユーザーに明示的に通知する。
```

### 要件設計書
markdown

```
# 要件設計書

## ドキュメント情報
- **ファイル名**: docs/requirements.md
- **目的**: 機能要件と非機能要件を明確に定義し、受け入れ基準を示す。

## 機能要件
1. **カメラプレビュー**: CameraX を用いたリアルタイムプレビューとフレーム取得。  
2. **モデルインポート**: ユーザーがモデルファイルをインポートできる。インポート時に暗号化保存。  
3. **ネイティブ復号**: 暗号化チャンクをストリーミング復号し、匿名 mmap でメモリに展開。  
4. **推論実行**: TFLite を用いたオンデバイス推論（NNAPI/GPU/CPU 切替）。  
5. **タイル合成**: 大きな画像はタイル処理で推論し、ガウス重みで合成。  
6. **翻訳**: オンデバイス翻訳（SentencePiece + small TFLite モデル）。  
7. **差分更新**: bsdiff 互換の差分適用と署名検証。  
8. **監査ログ**: 生成・操作・署名の監査ログを暗号化して保存。  
9. **自動テスト生成**: design/*.yaml から Kotlin/JUnit テスト雛形を生成。  
10. **CI ローカルワークフロー**: schema validation、dry-run、静的解析、テスト、SAST、カバレッジチェックを実行。

## 非機能要件
- **セキュリティ**: AES‑GCM 暗号化、Keystore 保護、署名検証。  
- **パフォーマンス**: small モデルで中央値 ≤ 800 ms（実機）。  
- **可用性**: アプリは低メモリ・高温環境でも安定稼働すること。  
- **保守性**: 自動生成ワークフローと監査ログにより変更履歴を追跡可能にする。  
- **プライバシー**: ユーザーデータは端末内に留める。外部送信はユーザー同意必須。

## 受け入れ基準
- 各機能はユニット・統合テストを通過すること。  
- カバレッジはモジュール単位で ≥ 80%。  
- セキュリティ検査（Frida/Root/Xposed）で誤検出がないこと。  
- 耐久テスト（60 分）で重大クラッシュなし。
```

### 機能設計書
markdown

```
# 機能設計書

## ドキュメント情報
- **ファイル名**: docs/functional_design.md
- **目的**: 各機能の詳細な振る舞い、API、エラー処理、データフローを定義する。

## 1 カメラプレビューとフレーム取得
- **API**
  ```kotlin
  suspend fun init(previewView: PreviewView, lifecycleOwner: LifecycleOwner, onFrame: suspend (ImageProxy)->Unit)
  fun stop()
  fun isCameraAvailable(): Boolean
  ```

- **振る舞い**: `ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST` を使用。`ThermalGuard.getThrottleMs()` による解析頻度制御。
- **例外**: `CameraPermissionException`, `CameraUnavailableException`

## 2 モデルインポートと保存

- **API**

```kotlin
suspend fun importFromUri(uri: Uri, displayName: String): ModelMeta
suspend fun listModels(): List<ModelMeta>
suspend fun deleteModel(name: String, version: String): Boolean
```
- **処理フロー**:

1. 一時保存（メモリまたは一時 FD）
2. マジックナンバー検査（`TFL3`）
3. SHA256 計算
4. 暗号化（AES‑GCM、Keystore 鍵）
5. 保存: `files/models/{name}/{version}/model.enc` と `meta.json`

## 3 ネイティブ復号とメモリマップ

- **JNI API**

```cpp
jlong loadModelFromEncryptedChunks(JNIEnv*, jobject, jobjectArray chunkPaths, jbyteArray keyBytes);
jobject getModelByteBuffer(JNIEnv*, jobject, jlong handle);
void freeModelHandle(JNIEnv*, jobject, jlong handle);
```
- **振る舞い**: チャンク形式 `iv(12) || ciphertext || tag(16)`。復号後は匿名 `mmap` にコピーし `mprotect(PROT_READ)` を適用。平文はディスクに残さない。

## 4 推論実行

- **API**

```kotlin
suspend fun loadModel(buffer: ByteBuffer, preferNNAPI:Boolean = true)
suspend fun runOnFrame(frame: ImageProxy): InferenceResult
suspend fun runOnTiles(bitmap: Bitmap, tileSize:Int = 256): InferenceResult
fun unloadModel()
```
- **出力**: `InferenceResult(masks, boxes, labels, scores, latencyMs)`
- **フォールバック**: GPU/NNAPI 失敗時は CPU にフォールバック。連続失敗 5 回でアンロード。

## 5 差分更新

- **API**

```kotlin
suspend fun applyDeltaUpdate(name: String, baseVersion: String, deltaBlob: ByteArray): Boolean
```
- **処理**: bsdiff 互換で差分を適用し、復元後に SHA256 と署名を検証。

## 6 翻訳

- **API**

```kotlin
suspend fun loadTranslationModel(pair: String, version: String)
suspend fun translateText(input: String, from: String?, to: String): TranslationResult
```
- **振る舞い**: SentencePiece トークナイザを使用し、TFLite int8 モデルで推論。オンデバイスで完結。

## 7 監査ログ

- **保存先**: `files/diag/` と `audit/logs/`
- **フォーマット**: JSON（`audit_log_schema.json` 準拠）
- **イベント**: 自動生成、apply、署名付きコミット、差分適用、セキュリティ検出

## 8 エラーハンドリング方針

- 軽微エラーはユーザーに再試行を促すUIで処理。
- 重大エラーはDiagに暗号化保存し、ユーザーに復旧手順を提示。
```