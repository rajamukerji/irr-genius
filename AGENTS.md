# Repository Guidelines

## Project Structure & Module Organization
- `ios/`: Native Swift/SwiftUI app. Key folders: `IRR Genius/Models`, `Views`, `Services`, `Data` (Core Data), `Utilities`. Tests in `IRR GeniusTests/` and `IRR GeniusUITests/`.
- `android/`: Native Kotlin/Compose app. Key folders under `app/`: `data/` (Room + repositories), `ui/` (`components/`, `screens/`, `theme/`), `validation/`, `services/`, `utils/`. Build files: `build.gradle.kts`, `settings.gradle.kts`.
- `shared/`: Cross‑platform docs, assets, and specs (`shared/docs`, `shared/assets`, `shared/specs`).
- `.kiro/specs/`: Additional specs powering AI-assisted workflows.

## Build, Test, and Development Commands
```bash
# iOS
cd ios && open "IRR Genius.xcodeproj"   # Build/run in Xcode (⌘R), tests (⌘U)

# Android
cd android && ./gradlew build            # Assemble and run checks
./gradlew installDebug                   # Install debug build on device/emulator
./gradlew test                           # JVM unit tests
./gradlew connectedAndroidTest           # Instrumented tests
```
Requirements: Java 17+, Gradle 8, AGP 8.1.4, Kotlin 1.9 (per README).
Notes: Xcode scheme runs SwiftFormat as a pre-build action; Android Gradle `preBuild` runs `ktlintFormat` if available.

## Coding Style & Naming Conventions
- Swift: Follow standard Swift API Design Guidelines and SwiftUI patterns (MVVM). Types `PascalCase` (e.g., `SavedCalculation`), properties/methods `lowerCamelCase`. Prefer explicit access control. Use Xcode’s formatter.
- Kotlin: Follow Kotlin coding conventions and Jetpack Compose best practices. Classes/objects `PascalCase`, functions/vars `lowerCamelCase`, constants `UPPER_SNAKE_CASE`. Use Android Studio formatting.
- Files mirror feature/domain folders (e.g., `ios/.../Services/CloudKitSyncService.swift`, `android/app/ui/screens/...`).

## Testing Guidelines
- iOS: Use Swift Testing; cover Core Data repos, CloudKit sync, import/export, validation. Run via Xcode (⌘U).
- Android: Use JUnit for unit tests; cover repositories, validation rules, export/sharing. Run `./gradlew test` and `connectedAndroidTest`.
- Add tests alongside platform modules; prefer deterministic tests for financial math (see `shared/specs/CALCULATIONS.md`).

## Commit & Pull Request Guidelines
- Commits follow Conventional Commits (e.g., `feat: ...`, `fix: ...`, `docs: ...`). Keep messages scoped and imperative.
- PRs: include a concise summary, linked issues, platform(s) affected, before/after screenshots when UI changes apply, and testing notes (simulator/device, OS/API levels).
- Ensure both platforms stay mathematically consistent; call out any divergence.

## Security & Configuration Tips
- iOS: CloudKit requires iCloud entitlements and a signed account. Avoid committing secrets.
- Android: Target Java 17+, min SDK 26. Do not include keystores or credentials.
- Data stays local unless CloudKit is enabled (see README). Validate and sanitize all user input.

## Formatting & Hooks
- Hooks: Run `scripts/setup-hooks.sh` to enable repo hooks (`.githooks`).
- Pre-commit: Formats Swift (SwiftFormat) and Kotlin (ktlint) if installed; blocks on unresolved issues.
- Commit messages: Enforced Conventional Commits via `commit-msg` hook.
- Format on demand: `scripts/format-ios.sh`, `scripts/format-android.sh`, or `scripts/format-all.sh`.
- Install tools: `brew install swiftformat ktlint` (or platform equivalents).
- CI/Build Integration: Xcode shared scheme pre-action runs SwiftFormat; Android tasks `ktlintFormat` and `ktlintCheck` are wired to `preBuild` and `check`.

## CI
- Workflow: `.github/workflows/ci.yml` runs on pushes/PRs to `main`.
- Android job (Ubuntu): installs JDK 17, Android SDK, ktlint; runs `ktlintCheck`, `build`, and `test`.
- iOS job (macOS): installs SwiftFormat (optional) and runs `xcodebuild test` on an iPhone 15 simulator.

### Releases
- Workflow: `.github/workflows/release.yml` triggers on tags `v*` or manual dispatch.
- Android: builds AAB on all runs; uploads to Play Internal only on tags (`v*`). Requires `PLAY_JSON` secret.
- iOS: runs Fastlane `tests` and `beta` (TestFlight upload) using App Store Connect API key secrets.
  - TestFlight upload runs only on tags (`v*`); manual runs execute tests but skip upload.
  - Manual runs can enable Android AAB build by setting `build_android_aab=true` in the dispatch form.

## Fastlane
- iOS lanes (`ios/fastlane/Fastfile`): `tests`, `beta` (TestFlight), `release` (App Store upload). Configure `ios/fastlane/Appfile` with `app_identifier`, `apple_id`, and team IDs.
- Android lanes (`android/fastlane/Fastfile`): `tests`, `beta` (Play internal via AAB), `release` (promote to production). Configure `android/fastlane/Appfile` with `json_key_file` and `package_name`.
- Install: `gem install fastlane` or use Bundler with the provided `Gemfile`.
- Usage examples:
  - iOS: `cd ios && fastlane beta`
  - Android: `cd android && fastlane beta`
- Secrets: Store Apple API keys and Google Play JSON outside the repo or inject via CI secrets. Do not commit credentials.
  - GitHub Secrets expected by release workflow:
    - `PLAY_JSON`: Google Play service account JSON contents.
    - `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY`: App Store Connect API Key triplet.

## Tagging a Release
- Update `CHANGELOG.md` with the new version and date.
- Use Semantic Versioning: `vMAJOR.MINOR.PATCH`.
- Commands:
  ```bash
  git pull origin main
  git tag -a v1.0.0 -m "release: v1.0.0"
  git push origin v1.0.0
  ```
- Pushing the tag triggers the release workflow: Android upload to Play Internal, iOS TestFlight upload.
