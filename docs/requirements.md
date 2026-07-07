# Requirements

**generated_at**: 2026-07-07T02:05:37Z  
**agent_id**: copilot_agent_local  
**design_ref**: design/complete_design.json

---
## Functional Requirements

- **AppLogger.info**: アプリ全体の構造化ログ出力を行う
- **AppLogger.error**: エラーの記録と監査ログへの転送
- **PhotoStudioService.processImage**: 画像の前処理、背景除去、露出補正、タイル分割を行う
- **PhotoStudioService.generatePreview**: プレビュー画像を生成し、保存パスを返す
- **PhotoStudioView.build**: UIを構築し、ViewModelの状態に応じて表示を切替
- **PhotoStudioViewModel.startProcessing**: UIからの要求を受け、PhotoStudioServiceを呼び出し状態遷移を管理する
- **PhotoStudioViewModel.observeState**: 状態ストリームを提供する
- **DescriptionGenerator.generateDescription**: 商品説明文をテンプレートとルールベースで生成する（外部有料APIは使用しない）
- **EncryptedStore.saveApiKey**: APIキーをローカル暗号化ストレージに保存する（Keystore保護）
- **EncryptedStore.getApiKey**: 保存されたAPIキーを取得する
- **AuditLogger.record**: 監査ログを暗号化して audit/logs/ に保存し、ファイル名を返す
