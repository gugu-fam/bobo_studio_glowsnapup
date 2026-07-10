# 実装反映チェックリスト

このチェックリストは、本ドキュメントの反映と実装準備が完了しているかを検証するためのものです。

- [ ] `docs/implementation_design_full.md` が存在し、設計が完全に記録されている。
- [ ] ネイティブローダー：`app/src/main/cpp/native_loader.cpp` の実装スケルトンが存在する。
- [ ] JNI ラッパー：`NativeLoader.kt` が存在し、ライブラリをロードするコードを含む。
- [ ] Kotlin サービス群のスケルトンが `app/src/main/java/com/bobo/glowsnapup/services/` に存在する。
- [ ] tools スクリプトのスケルトンが `tools/` に存在する。
- [ ] CI スクリプト `ci/validate_and_generate_local.sh` が存在する。
- [ ] 署名スクリプト `scripts/sign_commit.sh` が存在する。
- [ ] `tests/generated/` が存在する（プレースホルダ可）。
- [ ] `audit/logs/` ディレクトリが存在する（ログが保存できること）。

次のステップ:
- それぞれのスケルトンに詳細実装を加える（実装タスク化）。
- ユニットテストと CI パイプラインを実行して問題点を洗い出す。
