CI secrets and binary provisioning

1) MODEL_SIGNER_PEM (recommended)
  - Description: Base64-encoded PEM of the model signer public key used to verify delta updates.
  - Usage: Add repository secret `MODEL_SIGNER_PEM` containing the base64 of the PEM file. The CI workflow will decode it to `app/src/main/assets/keys/model_signer_pub.pem`.

2) BINARIES_ARTIFACT_URL (optional)
  - Description: URL (signed/internal) to a tar.gz containing required native tools (`bspatch`, `spm_encode`, `spm_decode`).
  - Usage: Set the env var in the CI job or repository secret; the workflow script `tools/ci/install_binaries.sh` will download and extract it to `files/bin`.

3) ANDROID keystore and signing
  - Use GH Actions secrets for `KEYSTORE_BASE64` and `KEYSTORE_PASSWORD` if you wish to sign APKs in CI. Decode `KEYSTORE_BASE64` to a file and configure Gradle's signing config.

Security notes:
  - Store private keys only in protected secrets and limit access.
  - Validate artifacts with checksums and avoid fetching binaries from untrusted public URLs.
