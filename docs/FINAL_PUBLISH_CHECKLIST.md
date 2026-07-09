# FINAL_PUBLISH_CHECKLIST.md

## 最終公開チェックリスト

- **秘密情報の除去**
  - リポジトリに秘密鍵、`secret-key.asc`、パスワード、トークン が含まれていないことを確認。
  - 推奨コマンド: `git ls-files | grep -E 'secret|private|password|.asc|.gpg'`
- **.gitignore の確認**
  - `archive/`, `dist/`, `reports/secure`、`dist-publish` ログ等が `.gitignore` に含まれていること。
- **公開鍵の配布準備**
  - `public_gpg_<KEYID>.asc` を `dist/` と `docs/` に置き、公開鍵の指紋を README に明記する。
- **検証手順の同梱**
  - `VERIFY.md` を `dist/` に同梱済みであることを確認。
- **署名とハッシュの最終確認**
  - 最新アーカイブに対して `sha256sum` と `gpg --verify` を実行し、ログを `reports/publish_logs/` に保存する。
- **鍵運用ポリシーの明示**
  - `KEY_ROTATION.md` を管理者向けに配布する（公開版に含める場合は機密部分を除外）。
- **ライセンスと配布物の明記**
  - `LICENSE` と `README` に配布条件と検証手順を明記する。
- **脆弱性・秘密検査**
  - `git-secrets` や `truffleHog` と同等のローカルチェックを行う（外部サービスを使わない場合はローカル実行）。
- **配布チャネルの決定**
  - 公開先のアクセス制御と監査要件を確認する。

## 公開時の推奨手順（簡潔）
1. 最終スキャン（秘密・脆弱性）
2. 最終署名・ハッシュ生成（`make ci`）
3. 公開鍵指紋を README に記載
4. リリースノート作成（検証手順含む）
5. 配布（GitHub Release / 公開サーバ等）
6. 配布ログを保存・監査記録に追加

## 公開後にやるべきこと（運用）
- 受け手からの検証報告窓口を用意する（Issue テンプレやメール）。
- 定期的に `reports/key_management/` をレビューし、鍵ローテーションを実行する。
- 重大問題発生時はリボーク→再配布手順を即時実行する。
