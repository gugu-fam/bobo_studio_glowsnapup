# KEY_ROTATION.md

## 目的
この文書は、署名鍵のバックアップ、ローテーション（定期更新）、失効（リボーク）、および緊急対応手順を明確にするための手順書です。ローカル完結運用における鍵管理の標準手順として運用してください。

---

## 用語

- **主鍵（Primary key）**: 長期的な管理用の GPG 鍵（必要に応じてサブキーを利用）。
- **サブキー（Subkey）**: 署名専用に使う鍵。主鍵はオフラインで保管し、日常の署名はサブキーで行う運用を推奨。
- **リボーク証明書（Revocation certificate）**: 鍵を失効させるための事前生成ファイル。

---

## 方針（要点）

1. **年次ローテーション**: 署名用サブキーは年に1回ローテーションする。主鍵はオフラインで長期保管し、必要時のみ使用する。
2. **バックアップ**: 秘密鍵のバックアップは暗号化してオフライン保管（複数の物理メディアに分散）。
3. **リボーク準備**: 鍵作成時にリボーク証明書を必ず生成し、安全なオフライン保管を行う。
4. **再署名手順**: 鍵ローテーション時に既存の配布物を再署名する手順を文書化しておく。

---

## 鍵の作成（推奨ワークフロー）

1. 主鍵をオフラインで生成（推奨: オフライン専用マシンまたはハードウェアトークン）

```
# 対話式で生成
gpg --full-generate-key
# 推奨: RSA 4096, 有効期限 0（無期限）で主鍵を作成し、署名用サブキーを追加
```

2. サブキー（署名専用）を作成し、日常の署名に使用する。サブキーは有効期限を設定（例: 1年）。

---

## リボーク証明書の生成（必須）
鍵を生成したら直ちにリボーク証明書を作成し、オフラインで保管します。

```
# <KEYID> は主鍵のキーIDまたは指紋
gpg --output revoke-<KEYID>.asc --gen-revoke <KEYID>
# revoke-<KEYID>.asc を暗号化してオフライン保管
```

---

## 秘密鍵のバックアップ（暗号化してオフライン）

1. 秘密鍵をエクスポート（ASCII armored）

```
gpg --armor --export-secret-keys <KEYID> > secret-key-<KEYID>.asc
```

2. エクスポートしたファイルをさらに GPG で暗号化して保管（別の管理者の公開鍵で暗号化するか、パスフレーズ付きアーカイブにする）

```
gpg --symmetric --cipher-algo AES256 --output secret-key-<KEYID>.asc.gpg secret-key-<KEYID>.asc
# secret-key-<KEYID>.asc は安全に削除
shred -u secret-key-<KEYID>.asc || rm -f secret-key-<KEYID>.asc
```

3. 暗号化ファイルを複数の物理メディアに分散して保管（例: 2 箇所以上）。保管場所は文書化しておく。

---

## 年次ローテーション手順（サブキー更新）

1. 新しいサブキーを生成（オフライン推奨）

```
# 既存鍵にサブキーを追加
gpg --edit-key <KEYID>
# コマンド内で: addkey -> RSA (sign only) -> 4096 -> 有効期限 1y -> save
```

2. 新しいサブキーをエクスポートして署名用ランナーにインポート（安全な手段で転送）

```
gpg --armor --export-secret-subkeys <KEYID> > secret-subkeys-<KEYID>.asc
# 転送後、受け取り側でインポート
gpg --batch --import secret-subkeys-<KEYID>.asc
```

3. 既存の配布物を再署名（必要な場合）

```
# 例: 再署名スクリプト
for f in archive/*.tar.gz; do
	gpg --armor --output "$f.asc" --detach-sign "$f"
	sha256sum "$f" > "$f.sha256"
done
```

4. 公開鍵を更新して配布（必要なら指紋の変更を受け手に通知）

```
gpg --armor --output public_gpg_<KEYID>.asc --export <KEYID>
```

---

## 緊急リボーク手順（鍵漏洩疑い）

1. 直ちにリボーク証明書を使用して鍵を失効させる（オフラインで実行可能）

```
gpg --import revoke-<KEYID>.asc
# 失効を公開鍵サーバや配布チャネルに反映する場合は公開鍵を再配布
gpg --armor --output public_gpg_<KEYID>.asc --export <KEYID>
```

2. 受け手に対して速やかに通知し、旧鍵で署名された配布物の信頼性を再評価する。必要なら再署名して再配布する。

3. 新しい鍵を生成し、上記のバックアップ・ローテーション手順に従う。

---

## 失効情報の配布

- 失効情報（リボーク証明書のインポート結果）と新しい公開鍵は、配布物の `reports/` と `dist/` に同梱し、受け手に通知する。
- 受け手には `VERIFY.md` の更新版を配布し、どの鍵が有効かを明示する。

---

## 監査ログと記録

- 鍵の生成・バックアップ・ローテーション・リボークの各イベントは `reports/key_management/` に日付付きでログを保存する。
- 例: `reports/key_management/20260709-create.log`, `reports/key_management/20270701-rotate.log`。

---

## 役割と責任

- **鍵管理者**: 鍵の生成、リボーク証明書の保管、バックアップの管理を担当。
- **配布担当**: 公開鍵の配布、配布物の再署名、受け手への通知を担当。
- **監査担当**: 監査ログの保管と定期レビューを担当。

---

## 付録: 便利なコマンド集

```
# 公開鍵の指紋確認
gpg --with-colons --fingerprint <KEYID>

# 秘密鍵の一時インポート（ファイルから）
gpg --batch --import secret-subkeys-<KEYID>.asc

# リボーク証明書の生成（再掲）
gpg --output revoke-<KEYID>.asc --gen-revoke <KEYID>

# 公開鍵のエクスポート
gpg --armor --output public_gpg_<KEYID>.asc --export <KEYID>
```

---

## 最後に
この手順は運用の基礎です。組織のセキュリティポリシーや監査要件に合わせて調整してください。鍵の取り扱いは慎重に行い、定期的に手順を見直してください。

### 生成と更新の完了報告
**完了** — 以下を作成・更新しました。

- **ファイル作成**: `VERIFY.md`, `KEY_ROTATION.md`
- **同梱**: `VERIFY.md` を `dist/` に同梱済み
- **ログ管理**: `reports/publish_logs/` を作成し `dist-publish-*.log` を移動
- **スクリプト更新**: `dist-publish.sh` にログ出力先と簡易ローテーション（最大30個）を追加、`dist.sh` は `VERIFY.md` を同梱するよう更新

### 推奨の次ステップ（短く）

1. **A — KEY_ROTATION.md を拡充**（具体的コマンド列、リボーク手順を追加） — **推奨**


