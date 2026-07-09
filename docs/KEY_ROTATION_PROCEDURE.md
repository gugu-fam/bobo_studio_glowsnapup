# KEY_ROTATION_PROCEDURE.md

## 概要
この手順はサブキーの年次ローテーションを想定した具体的手順です。オフラインでの作業を前提とします。

## 準備

1. 作業日時と担当者を決定し関係者へ通知する。コミュニケーションチャネルを確保する（オフライン作業時の連絡手段含む）。
2. オフライン用マシンを用意しネットワークを切断する。必要なツール（gpg, usbメディア, エンクリプタ）を準備する。
3. `reports/key_management/` に作業ログ用ディレクトリを作成する。

## 手順（詳細）

### 1) 現行の確認

- 現行公開鍵の指紋を記録する:

```
gpg --with-colons --fingerprint <KEYID>
```

- リボーク証明書とバックアップの有無を確認する。

### 2) 新しいサブキーの作成（オフライン）

1. オフラインマシンで `gpg --edit-key <KEYID>` を実行
2. コマンド内で `addkey` を選択し、`RSA (sign only)`、`4096`、有効期限 `1y` などを設定する
3. `save` して終了する

### 3) リボーク生成（必要なら）

```
./scripts/gen_revoke.sh <KEYID> reports/key_management
```

生成した証明書はオフラインで安全に保管する。

### 4) サブキーのエクスポート（転送用）

```
./scripts/export_subkeys.sh <KEYID> reports/key_management
```

出力は `reports/key_management/secret-subkeys-<KEYID>-YYYYMMDD_HHMMSS.asc.gpg` となる。安全チャネルで署名ランナーへ転送する。

### 5) 受け取り側でのインポートと確認

受け取り側（署名を行うマシン）でインポート:

```
gpg --import secret-subkeys-<KEYID>-*.asc.gpg
```

テスト署名を作成し、検証を行う:

```
echo test > /tmp/testfile
gpg --detach-sign -o /tmp/testfile.asc /tmp/testfile
gpg --verify /tmp/testfile.asc /tmp/testfile
```

### 6) 必要なら既存配布物の再署名

```
for f in archive/*.tar.gz; do
  gpg --armor --output "$f.asc" --detach-sign "$f"
  sha256sum "$f" > "$f.sha256"
done
```

### 7) 公開鍵の更新と配布

```
gpg --armor --output public_gpg_<KEYID>.asc --export <KEYID>
# 配布物に同梱し、受け手に指紋を通知
```

### 8) ログ保存

作業ログ（出力、コマンド、指紋、タイムスタンプ）は `reports/key_management/YYYYMMDD-rotate.log` に保存する。

## ロールと責任

- 鍵管理者: 鍵生成・リボーク保管・バックアップ管理
- 配布担当: 公開鍵配布・再署名・受け手通知
- 監査担当: ログレビューと保管

## 付録: 重要な注意点

- 秘密鍵はオンライン環境に長時間置かない。必要時のみ短時間で扱い、作業終了後は安全に削除する。 
- リボーク証明書は鍵を失効させるための最終手段。必ずオフラインで保管する。
