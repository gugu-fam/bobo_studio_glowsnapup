# bobo_studio_glowsnapup

Initial main branch for repository.

## 公開鍵情報（検証用）

- **Key ID**: 34E99ECD52FE1A446FC8CFB2079F1148E9F2C635
- **Fingerprint**: 34E99ECD52FE1A446FC8CFB2079F1148E9F2C635

検証コマンド例:
```bash
gpg --import dist/public_gpg_34E99ECD52FE1A446FC8CFB2079F1148E9F2C635.asc
gpg --with-fingerprint --list-keys 34E99ECD52FE1A446FC8CFB2079F1148E9F2C635
sha256sum -c <archive>.sha256
gpg --verify <archive>.tar.gz.asc <archive>.tar.gz
```
