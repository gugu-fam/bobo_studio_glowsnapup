Development environment notes

- Java: Use JDK 21 for running Android unit tests (Robolectric SDK 36 requires Java 21).
  - macOS / Linux: install Temurin/OpenJDK 21 and ensure `java -version` reports major 21.
  - CI: workflows are configured to use JDK 21.

- Running unit tests locally (Android module):
  ```bash
  cd android
  ./gradlew test
  ```

- If tests fail with `UnsupportedOperationException` from `DefaultSdkProvider`, ensure your local Java version >=21 and that Android SDKs for the Robolectric target are available.
