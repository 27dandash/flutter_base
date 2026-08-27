# Command log — 2026-08-26/27 hardening audit

No Git command was executed. Commands were run from the target root unless a
different working directory is shown. The explicit Flutter SDK was
`/Users/abdelrahamndandash/Documents/SDK/flutter 2`.

## Read-only discovery

```bash
find /Users/abdelrahamndandash/StudioProjects ... -name pubspec.yaml
rg --files lib test docs packages .claude .cursor md
rg -n <component/import/config patterns> <target and read-only reference roots>
sed -n <requested ranges> <inspected source/docs/instruction files>
wc -l -c <instruction and source inventories>
shasum -a 256 <repeated generic reference implementations>
flutter --version
java -version
df -h /
du -sh build .dart_tool android/.gradle
```

Project discovery pruned `.git`, `build`, `.dart_tool`, `.gradle`, `Pods`, SDK,
archive, cache and backup directories. Reference-project commands were limited
to `find`, `rg`, `sed`, `wc` and `shasum`.

## Backup and local skill

```bash
tar -czf .../work/backups/flutter-base-pre-hardening-20260826.tar.gz <changed-file set>
shasum -a 256 .../work/backups/flutter-base-pre-hardening-20260826.tar.gz
python3 .../skill-creator/scripts/init_skill.py flutter-base-production --path .codex/skills --resources references
python3 -m pip install --target .../work/skill-validator-deps PyYAML
PYTHONPATH=.../work/skill-validator-deps python3 .../skill-creator/scripts/quick_validate.py .codex/skills/flutter-base-production
tar -czf .../work/backups/flutter-base-size-script-pre-update-20260827.tar.gz scripts/check_size_budget.sh .github/workflows/flutter_quality.yml
```

The validator initially failed because its host Python lacked `yaml`; PyYAML
was installed only in the task work directory and validation then passed.

## Format, analysis and tests

```bash
flutter pub get
dart format <changed Dart files>
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter=json
flutter test --coverage --reporter=compact
flutter test --dart-define=PHP_RESPONSE_MODE=false --reporter=json test/core/network/php/php_envelope_test.dart
```

Optional packages, each from its own directory:

```bash
flutter analyze
flutter test
```

This was repeated for `app_notifications`, `app_remote_config`, `app_webview`,
`app_maps`, and `app_socket`.

Dependency evidence:

```bash
flutter pub outdated --no-dev-dependencies
flutter pub deps --style=compact
cd android && ./gradlew app:dependencies --configuration productionReleaseRuntimeClasspath
curl -H 'Content-Type: application/json' --data-binary @osv-pub-query.json https://api.osv.dev/v1/querybatch
```

## Android builds and inspection

```bash
flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart --target-platform android-arm64 --analyze-size
flutter build apk --release --flavor production -t lib/main_production.dart --target-platform android-arm64 --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart --split-debug-info=build/symbols/production
apkanalyzer manifest debuggable build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer apk summary build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer dex list build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer files list build/app/outputs/flutter-apk/app-production-release.apk
ESTIMATED_DOWNLOAD_BYTES=9247946 DART_AOT_BYTES=5047176 NATIVE_LIBRARY_BYTES=11879416 ./scripts/check_size_budget.sh
```

`flutter clean` followed by `flutter pub get` was used between debug, Android
release and iOS matrices because the 8 GiB free-space ceiling could not retain
all generated intermediates together. Two build attempts failed only with
`No space left on device`; after target-only generated cleanup, every matrix
entry passed. No reference project was cleaned.

## Bundletool and Samsung smoke

```bash
curl -L --fail https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar -o .../work/bundletool-all-1.18.3.jar
java -jar bundletool-all-1.18.3.jar get-device-spec --device-id=R58TA0LQH8E --output=samsung-a23-device.json --overwrite
java -jar bundletool-all-1.18.3.jar build-apks --bundle=app-production-release.aab --output=production-samsung-final.apks --device-spec=samsung-a23-device.json --overwrite
java -jar bundletool-all-1.18.3.jar get-size total --apks=production-samsung-final.apks --device-spec=samsung-a23-device.json
java -jar bundletool-all-1.18.3.jar install-apks --apks=production-samsung.apks --device-id=R58TA0LQH8E
adb -s R58TA0LQH8E logcat -c
adb -s R58TA0LQH8E shell am force-stop com.example.clean_arch_base
adb -s R58TA0LQH8E shell monkey -p com.example.clean_arch_base -c android.intent.category.LAUNCHER 1
adb -s R58TA0LQH8E shell pidof com.example.clean_arch_base
adb -s R58TA0LQH8E logcat -d '*:E'
```

## iOS matrix

```bash
flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart
du -sk build/ios/iphonesimulator/Runner.app
```

## Matched control and symbol retention

The temporary control used `flutter create`, then the same AGP/Gradle/Kotlin,
production flavor, R8 and resource-shrink settings were applied. Commands:

```bash
flutter build apk --release --flavor production -t lib/main.dart
flutter build apk --release --flavor production -t lib/main.dart --target-platform android-arm64 --analyze-size
flutter build appbundle --release --flavor production -t lib/main.dart --split-debug-info=build/symbols/production
bundletool build-apks ... --device-spec=samsung-a23-device.json
bundletool get-size total ... --device-spec=samsung-a23-device.json
trash .../work/flutter-size-control-20260827
```

Final root symbols were retained with:

```bash
tar -czf .../work/production-symbols-final-20260827.tar.gz build/symbols/production build/app/outputs/mapping/productionRelease build/app/outputs/native-debug-symbols/productionRelease
shasum -a 256 .../work/production-symbols-final-20260827.tar.gz
```

## Widget-hardening phase

```bash
tar -czf .../work/backups/flutter-base-pre-widget-hardening-20260827.tar.gz <target base>
dart format --output=none --set-exit-if-changed lib test packages
flutter analyze --no-pub
flutter test --no-pub --reporter=compact
flutter test --no-pub --coverage test/core/widgets
flutter test --no-pub --coverage
flutter test --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart

for package in app_notifications app_remote_config app_webview app_maps app_socket; do
  cd packages/$package
  flutter pub get
  flutter analyze --no-pub
  flutter test --no-pub
done

flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --target-platform android-arm64 --analyze-size

flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart

flutter pub deps --style=compact --no-dev
unzip -l app-production-universal-release.apk
apkanalyzer apk summary app-production-universal-release.apk
apkanalyzer manifest debuggable app-production-universal-release.apk
bundletool build-apks --device-spec=samsung-a23-device.json ...
bundletool get-size total --device-spec=samsung-a23-device.json ...
bundletool install-apks --device-id=R58TA0LQH8E ...
adb -s R58TA0LQH8E logcat ...
```

The first optional-package recheck after `flutter clean` intentionally stopped
when package resolution was absent. `flutter pub get` was then run inside each
target-owned optional package and all five analyzers/tests passed. A transient
Gradle cache miss after disk pressure was repaired with
`./gradlew help --refresh-dependencies --no-daemon`; no cache directory or
reference project was manually deleted.

## Compatibility-consolidation verification

```bash
tar -czf .../work/backups/flutter-base-widget-consolidation-20260827.tar.gz <targeted widget/test/docs paths>
dart format --output=none --set-exit-if-changed lib test packages
flutter analyze --no-pub
flutter test --no-pub
flutter test --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart
flutter test --coverage test/core/widgets
flutter test --coverage

flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter clean
flutter pub get
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart

bundletool build-apks --device-spec=samsung-a23-device.json ...
bundletool get-size total --device-spec=samsung-a23-device.json ...
bundletool install-apks --device-id=R58TA0LQH8E ...
adb -s R58TA0LQH8E logcat ...
```

All matrices passed. The final Samsung bundletool estimate is 9,248,252 bytes;
the release process remained alive with no fatal app exception. Built-in
Kotlin migration remains an explicit future Flutter-toolchain warning.

## Final documentation/tooling consistency gate

The project-local quality gate was added and then executed without its optional
build flag because the expensive build matrix and release artifacts had already
been verified and retained:

```bash
bash -n scripts/flutter_quality_gate.sh
scripts/flutter_quality_gate.sh release
wc -c build/app/outputs/bundle/productionRelease/app-production-release.aab
shasum -a 256 build/app/outputs/bundle/productionRelease/app-production-release.aab
```

`quick` covers format, root analysis/tests, the PHP inverse and root optional
isolation. `full` adds root coverage and every optional analyzer/test. `release`
adds available size/artifact isolation gates; `release --build` is the explicit
expensive build opt-in. The gate executes no Git command and never touches a
reference project.

The first consistency run exposed that the shell `PATH` still named Flutter
3.38.9 / Dart 3.10.8 while the project resolution named Flutter 3.47.1 / Dart
3.13.1. The script was corrected to derive `flutter.sdk` from the project
configuration without embedding an absolute path. The final configured-SDK
run passed 19 checks with zero skips, reported 219 root tests plus two expected
skips, 15 PHP-inverse tests plus three opposite-branch skips, 32 optional tests,
and 2,435/4,069 covered root lines (59.84%).

## Dependency, live-runtime, skills and prompt-system phase

The configured SDK path was used for direct commands; the quality gate resolves
the same SDK from `android/local.properties` without embedding it.

```bash
flutter --version
flutter doctor -v
java -version
./android/gradlew --version
xcodebuild -version
pod --version
swift --version

flutter pub outdated --json
flutter pub upgrade --dry-run
flutter pub upgrade
flutter pub get
flutter pub deps --style=compact
curl -fsS -H 'Content-Type: application/json' --data <querybatch> \
  https://api.osv.dev/v1/querybatch

dart run build_runner build
dart run tool/generate_locale_keys.dart
./scripts/check_codegen_reproducibility.sh
./scripts/validate_agent_instructions.sh
./scripts/validate_prompt_library.sh

flutter test test/integration/live_http_stack_test.dart --no-pub
flutter test integration_test/widget_gallery_live_test.dart \
  -d emulator-5554 --flavor development --no-pub
flutter test integration_test/base_runtime_smoke_test.dart \
  -d emulator-5556 --flavor development --no-pub
flutter test integration_test/widget_gallery_live_test.dart \
  -d B20E1D04-857B-443F-AA98-FE567A431F57 \
  --flavor development --no-pub
flutter test integration_test/base_runtime_smoke_test.dart \
  -d B20E1D04-857B-443F-AA98-FE567A431F57 \
  --flavor development --no-pub
flutter test test/core/widgets --no-pub --reporter=compact

flutter clean
flutter pub get
./scripts/flutter_quality_gate.sh quick
./scripts/flutter_quality_gate.sh full
./scripts/flutter_quality_gate.sh release --build

apkanalyzer manifest debuggable \
  build/app/outputs/flutter-apk/app-production-universal-release.apk
apkanalyzer dex list \
  build/app/outputs/flutter-apk/app-production-universal-release.apk
wc -c build/app/outputs/flutter-apk/*.apk \
  build/app/outputs/bundle/productionRelease/app-production-release.aab
shasum -a 256 build/app/outputs/flutter-apk/*.apk \
  build/app/outputs/bundle/productionRelease/app-production-release.aab
```

The Android 16 release smoke used `apksigner` on a temporary copy with an
ephemeral QA-only key, then `adb install`, `am start`, HOME/resume, two Retry
taps, screenshot inspection and PID-filtered logcat. Signing material was
removed immediately. The original unsigned artifact was not modified.

Two negative environmental attempts were retained as evidence: the existing
Android emulator rejected the 128 MB debug test APK for insufficient storage,
and the Samsung SM-A235F was keyguard-locked, so its secure-storage integration
test could not complete. A fresh temporary AVD was created from the already
installed API 36 image, used for the successful full-base smoke, and deleted
afterwards. No existing AVD or reference-project data was erased.
