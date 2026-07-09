# VERIFY.md

目的
---
このドキュメントは、配布物（`dist/`）を受け取った受け手が SHA256 と GPG 署名で配布物の整合性と真正性を検証するための最小手順を示します。

基本コマンド例
---

```bash
sha256sum -c bobo_studio_glowsnapup-20260709.tar.gz.sha256
gpg --import public_gpg_34E99ECD52FE1A446FC8CFB2079F1148E9F2C635.asc
gpg --verify bobo_studio_glowsnapup-20260709.tar.gz.asc bobo_studio_glowsnapup-20260709.tar.gz
```

保存
---
検証出力は監査のために保存してください（例: `gpg --verify ... 2>&1 | tee gpg_verify_YYYYMMDD.txt`）。

注意
---
- 公開鍵の指紋は配布元の別チャネルで事前に確認してください。
- 秘密鍵や `secret-key.asc` を絶対に含めないでください。
