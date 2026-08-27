#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODE="quick"
BUILD_RELEASES=0
PASSED_CHECKS=0
SKIPPED_CHECKS=0
CURRENT_CHECK="startup"
FLUTTER_BIN=""
DART_BIN=""
RELEASE_STAGE_DIR=""

usage() {
  cat <<'EOF'
Usage: scripts/flutter_quality_gate.sh [project-root] [quick|full|release] [--build]

Modes:
  quick    Instruction/prompt validation, format verification, root
           analyzer/tests, PHP inverse and root optional-integration isolation.
  full     Quick checks with root coverage, plus every optional-package
           analyzer/test suite and clean code-generation reproduction.
  release  Full checks plus size budgets and APK isolation when the verified
           artifacts are present.

Options:
  --build  With release mode only, rebuild the Android flavor/release matrix
           and the iOS simulator flavor matrix before artifact checks.
  -h, --help

This script never runs Git. Dependency resolution must already exist; run
flutter pub get in the root and each optional package explicitly when setting
up a new machine.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 2
}

on_error() {
  local status=$?
  if [[ -n "$RELEASE_STAGE_DIR" && -d "$RELEASE_STAGE_DIR" ]]; then
    echo "Preserved release evidence stage: $RELEASE_STAGE_DIR" >&2
  fi
  echo "QUALITY GATE FAILED: $CURRENT_CHECK (exit $status)" >&2
  exit "$status"
}
trap on_error ERR

for argument in "$@"; do
  case "$argument" in
    quick|full|release)
      MODE="$argument"
      ;;
    --build)
      BUILD_RELEASES=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -d "$argument" ]]; then
        requested_root="$(cd "$argument" && pwd)"
        [[ "$requested_root" == "$PROJECT_ROOT" ]] ||
          fail "This project-local gate only runs from its own project root."
      else
        fail "Unknown argument: $argument"
      fi
      ;;
  esac
done

if ((BUILD_RELEASES)) && [[ "$MODE" != "release" ]]; then
  fail "--build is available only with release mode."
fi

cd "$PROJECT_ROOT"

run_check() {
  local label="$1"
  shift
  CURRENT_CHECK="$label"
  echo "==> $label"
  "$@"
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

skip_check() {
  echo "--> SKIP: $1"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is unavailable: $1"
}

resolve_flutter_sdk() {
  local configured_sdk=""
  local key
  local value

  if [[ -f "android/local.properties" ]]; then
    while IFS='=' read -r key value; do
      if [[ "$key" == "flutter.sdk" ]]; then
        configured_sdk="$value"
        break
      fi
    done < "android/local.properties"
  fi

  if [[ -n "$configured_sdk" && -x "$configured_sdk/bin/flutter" ]]; then
    FLUTTER_BIN="$configured_sdk/bin/flutter"
    DART_BIN="$configured_sdk/bin/dart"
  else
    FLUTTER_BIN="$(command -v flutter || true)"
    DART_BIN="$(command -v dart || true)"
  fi

  [[ -n "$FLUTTER_BIN" && -x "$FLUTTER_BIN" ]] ||
    fail "No executable Flutter SDK matches the project configuration."
  [[ -n "$DART_BIN" && -x "$DART_BIN" ]] ||
    fail "No executable Dart SDK matches the project configuration."

  echo "Using Flutter SDK: $FLUTTER_BIN"
  "$FLUTTER_BIN" --version | sed -n '1p'
}

require_resolution() {
  local directory="$1"
  [[ -f "$directory/.dart_tool/package_config.json" ]] ||
    fail "Missing dependency resolution in $directory; run flutter pub get there first."
}

check_root_optional_isolation() {
  local dependency_graph
  dependency_graph="$("$FLUTTER_BIN" pub deps --style=compact --no-dev)"
  if printf '%s\n' "$dependency_graph" | grep -Eiq \
    'app_(notifications|remote_config|webview|maps|socket)|firebase_(core|messaging|remote_config)|awesome_notifications|google_maps_flutter|webview_flutter|socket_io_client'; then
    printf '%s\n' "$dependency_graph" | grep -Ei \
      'app_(notifications|remote_config|webview|maps|socket)|firebase_(core|messaging|remote_config)|awesome_notifications|google_maps_flutter|webview_flutter|socket_io_client' >&2
    echo "An optional concrete integration entered the root dependency graph." >&2
    return 1
  fi
  echo "Root dependency graph contains no forbidden optional integration."
}

print_coverage_summary() {
  local report="coverage/lcov.info"
  [[ -f "$report" ]] || fail "Coverage completed without producing $report."
  awk '
    /^LF:/ { found += substr($0, 4) }
    /^LH:/ { hit += substr($0, 4) }
    END {
      if (found == 0) exit 1
      printf "Root coverage: %d/%d lines (%.2f%%)\n", hit, found, hit * 100 / found
    }
  ' "$report"
}

analyze_optional_package() {
  local package="$1"
  (
    cd "packages/$package"
    "$FLUTTER_BIN" analyze --no-pub
  )
}

test_optional_package() {
  local package="$1"
  (
    cd "packages/$package"
    "$FLUTTER_BIN" test --no-pub --reporter=compact
  )
}

analyze_optional_example() {
  local package="$1"
  (
    cd "packages/$package/example"
    "$FLUTTER_BIN" analyze --no-pub
  )
}

test_optional_example() {
  local package="$1"
  (
    cd "packages/$package/example"
    "$FLUTTER_BIN" test --no-pub --reporter=compact
  )
}

remove_reproducible_directory() {
  local target="$1"

  case "$target" in
    "$PROJECT_ROOT/build"|"$PROJECT_ROOT/.dart_tool/flutter_build"|"$PROJECT_ROOT/packages/"*/example/build)
      ;;
    *)
      fail "Refusing to clean an unexpected release path: $target"
      ;;
  esac

  if [[ -d "$target" ]]; then
    find "$target" -depth -delete
  fi
}

reset_root_flutter_build_cache() {
  remove_reproducible_directory "$PROJECT_ROOT/.dart_tool/flutter_build"
  echo "Root Flutter build cache reset for fresh external Dart symbols."
}

begin_release_evidence_stage() {
  [[ -z "$RELEASE_STAGE_DIR" ]] ||
    fail "Release evidence staging is already active."
  RELEASE_STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/flutter-base-release-stage.XXXXXX")"
  mkdir -p "$RELEASE_STAGE_DIR/root_build/app/outputs"
  echo "Release evidence stage: $RELEASE_STAGE_DIR"
}

stage_root_build_path() {
  local relative="$1"
  local required="${2:-required}"
  local source
  local destination

  [[ -n "$RELEASE_STAGE_DIR" && -d "$RELEASE_STAGE_DIR" ]] ||
    fail "Release evidence stage is unavailable."

  source="$PROJECT_ROOT/build/$relative"
  if [[ ! -e "$source" ]]; then
    [[ "$required" == "optional" ]] && return 0
    fail "Required release evidence is missing: build/$relative"
  fi

  destination="$RELEASE_STAGE_DIR/root_build/$relative"
  [[ ! -e "$destination" ]] ||
    fail "Release evidence was staged more than once: build/$relative"
  mkdir -p "$(dirname "$destination")"
  mv "$source" "$destination"
}

stage_android_build_outputs() {
  local label="$1"
  shift
  local relative

  for relative in "$@"; do
    stage_root_build_path "$relative"
  done

  remove_reproducible_directory "$PROJECT_ROOT/build"
  echo "$label preserved; root build intermediates reclaimed."
}

stage_root_ios_app() {
  local flavor="$1"
  local source="$PROJECT_ROOT/build/ios/iphonesimulator/Runner.app"
  local destination="$RELEASE_STAGE_DIR/ios_apps/$flavor/Runner.app"

  [[ -d "$source" ]] || fail "Missing iOS $flavor simulator application."
  mkdir -p "$(dirname "$destination")"
  mv "$source" "$destination"
  remove_reproducible_directory "$PROJECT_ROOT/build"
  echo "Preserved iOS $flavor simulator application and reclaimed intermediates."
}

restore_release_evidence() {
  [[ -n "$RELEASE_STAGE_DIR" && -d "$RELEASE_STAGE_DIR/root_build" ]] ||
    fail "Release evidence cannot be restored."
  [[ ! -e "$PROJECT_ROOT/build" ]] ||
    remove_reproducible_directory "$PROJECT_ROOT/build"

  mv "$RELEASE_STAGE_DIR/root_build" "$PROJECT_ROOT/build"
  if [[ -d "$RELEASE_STAGE_DIR/ios_apps" ]]; then
    mkdir -p "$PROJECT_ROOT/build/post_identity_ios"
    mv "$RELEASE_STAGE_DIR/ios_apps"/* "$PROJECT_ROOT/build/post_identity_ios/"
  fi
  find "$RELEASE_STAGE_DIR" -depth -delete
  RELEASE_STAGE_DIR=""
  echo "Release artifacts, symbols, mappings, and iOS evidence restored."
}

clean_optional_example_build() {
  local package="$1"
  remove_reproducible_directory "$PROJECT_ROOT/packages/$package/example/build"
  echo "Reclaimed reproducible $package example build output."
}

create_native_symbol_archive() {
  local source="$PROJECT_ROOT/build/app/intermediates/merged_native_libs/productionRelease/mergeProductionReleaseNativeLibs/out/lib"
  local destination="$PROJECT_ROOT/build/app/outputs/native-debug-symbols/productionRelease"
  local archive="$destination/native-debug-symbols.zip"
  local staging

  [[ -d "$source" ]] ||
    fail "Unstripped production native libraries are unavailable."
  require_command zip
  staging="$(mktemp -d "$PROJECT_ROOT/build/native-symbol-stage.XXXXXX")"
  mkdir -p "$staging/lib" "$destination"
  cp -R "$source"/. "$staging/lib/"
  (
    cd "$staging"
    zip -q -r "$archive" lib
  )
  find "$staging" -depth -delete
  [[ -s "$archive" ]] || fail "External native symbol archive is empty."
  echo "External native symbols: $archive"
}

build_release_matrix() {
  begin_release_evidence_stage
  run_check "Android development debug build" \
    "$FLUTTER_BIN" build apk --debug --flavor development \
      -t lib/main_development.dart --target-platform android-arm64
  run_check "Preserve Android development debug evidence" \
    stage_android_build_outputs "Android development debug artifact" \
      app/outputs/flutter-apk/app-development-debug.apk
  run_check "Android staging debug build" \
    "$FLUTTER_BIN" build apk --debug --flavor staging \
      -t lib/main_staging.dart --target-platform android-arm64
  run_check "Preserve Android staging debug evidence" \
    stage_android_build_outputs "Android staging debug artifact" \
      app/outputs/flutter-apk/app-staging-debug.apk
  run_check "Android production debug build" \
    "$FLUTTER_BIN" build apk --debug --flavor production \
      -t lib/main_production.dart --target-platform android-arm64
  run_check "Preserve Android production debug evidence" \
    stage_android_build_outputs "Android production debug artifact" \
      app/outputs/flutter-apk/app-production-debug.apk
  run_check "Reset Flutter AOT cache before symbol generation" \
    reset_root_flutter_build_cache
  run_check "Production universal APK with external Dart symbols" \
    "$FLUTTER_BIN" build apk --release --flavor production \
      -t lib/main_production.dart \
      --split-debug-info="$PROJECT_ROOT/build/symbols/production"
  run_check "Preserve universal APK for later checks" \
    cp build/app/outputs/flutter-apk/app-production-release.apk \
      build/app/outputs/flutter-apk/app-production-universal-release.apk
  run_check "Preserve universal APK and Dart symbols" \
    stage_android_build_outputs "Universal APK and Dart symbols" \
      app/outputs/flutter-apk/app-production-release.apk \
      app/outputs/flutter-apk/app-production-universal-release.apk \
      symbols/production
  run_check "Production split-per-ABI APKs with external Dart symbols" \
    "$FLUTTER_BIN" build apk --release --flavor production \
      -t lib/main_production.dart --split-per-abi \
      --split-debug-info="$PROJECT_ROOT/build/symbols/production"
  run_check "Preserve split-per-ABI APKs" \
    stage_android_build_outputs "Split-per-ABI APKs" \
      app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk \
      app/outputs/flutter-apk/app-arm64-v8a-production-release.apk \
      app/outputs/flutter-apk/app-x86_64-production-release.apk
  run_check "Production AAB with external Dart symbols" \
    "$FLUTTER_BIN" build appbundle --release --flavor production \
      -t lib/main_production.dart \
      --split-debug-info="$PROJECT_ROOT/build/symbols/production"
  run_check "Create external native symbol archive" \
    create_native_symbol_archive
  run_check "Preserve AAB, mappings, and native symbols" \
    stage_android_build_outputs "AAB, mappings, and native symbols" \
      app/outputs/bundle/productionRelease \
      app/outputs/mapping/productionRelease \
      app/outputs/native-debug-symbols/productionRelease

  if [[ "$(uname -s)" == "Darwin" ]]; then
    run_check "iOS development simulator build" \
      "$FLUTTER_BIN" build ios --simulator --flavor development \
        -t lib/main_development.dart
    run_check "Preserve iOS development simulator evidence" \
      stage_root_ios_app development
    run_check "iOS staging simulator build" \
      "$FLUTTER_BIN" build ios --simulator --flavor staging \
        -t lib/main_staging.dart
    run_check "Preserve iOS staging simulator evidence" \
      stage_root_ios_app staging
    run_check "iOS production simulator build" \
      "$FLUTTER_BIN" build ios --simulator --flavor production \
        -t lib/main_production.dart
    run_check "Preserve iOS production simulator evidence" \
      stage_root_ios_app production
  else
    skip_check "iOS simulator matrix requires macOS."
  fi
}

check_release_artifacts() {
  local arm64_apk="build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk"
  local universal_apk="build/app/outputs/flutter-apk/app-production-universal-release.apk"
  local aab="build/app/outputs/bundle/productionRelease/app-production-release.aab"

  if [[ -f "$arm64_apk" && -f "$aab" ]]; then
    run_check "Release size budgets" ./scripts/check_size_budget.sh "$arm64_apk" "$aab"
  else
    skip_check "Size budgets need both the ARM64 split APK and production AAB; use release --build or restore the audited artifacts."
  fi

  if [[ -f "$universal_apk" ]]; then
    require_command unzip
    run_check "Universal APK optional-integration isolation" \
      check_universal_apk_isolation "$universal_apk"
  else
    skip_check "Universal APK entry isolation needs app-production-universal-release.apk; use release --build."
  fi
}

check_universal_apk_isolation() {
  local universal_apk="$1"
  local entries
  entries="$(unzip -Z1 "$universal_apk")"
  if printf '%s\n' "$entries" | grep -Eiq \
    'firebase|awesome_notifications|google_maps|webview_flutter|socket_io'; then
    printf '%s\n' "$entries" | grep -Ei \
      'firebase|awesome_notifications|google_maps|webview_flutter|socket_io' >&2
    echo "An optional concrete integration entered the Universal APK." >&2
    return 1
  fi
  echo "Universal APK entries contain no forbidden optional integration."
}

require_command grep
require_command sed
resolve_flutter_sdk
require_resolution "."

run_check "Shell script syntax" bash -n \
  scripts/flutter_quality_gate.sh scripts/check_optional_resolution.sh \
  scripts/check_size_budget.sh scripts/check_codegen_reproducibility.sh \
  scripts/check_project_identity.sh \
  scripts/validate_agent_instructions.sh scripts/validate_prompt_library.sh \
  scripts/new_feature.sh scripts/remove_demo.sh
run_check "Project-local agent instructions" \
  scripts/validate_agent_instructions.sh
run_check "Cross-platform project identity" scripts/check_project_identity.sh
run_check "Reusable prompt library" scripts/validate_prompt_library.sh
run_check "Dart format verification" \
  "$DART_BIN" format --output=none --set-exit-if-changed \
    lib test integration_test tool \
    packages/app_notifications/lib packages/app_notifications/test \
    packages/app_remote_config/lib packages/app_remote_config/test \
    packages/app_remote_config/example/lib packages/app_remote_config/example/test \
    packages/app_socket/lib packages/app_socket/test \
    packages/app_webview/lib packages/app_webview/test \
    packages/app_webview/example/lib packages/app_webview/example/test \
    packages/app_maps/lib packages/app_maps/test \
    packages/app_maps/example/lib packages/app_maps/example/test
run_check "Root analyzer" "$FLUTTER_BIN" analyze --no-pub

if [[ "$MODE" == "quick" ]]; then
  run_check "Root tests" "$FLUTTER_BIN" test --no-pub --reporter=compact
else
  run_check "Root tests with coverage" \
    "$FLUTTER_BIN" test --no-pub --coverage --reporter=compact
  run_check "Coverage summary" print_coverage_summary
fi

run_check "PHP inverse-mode tests" \
  "$FLUTTER_BIN" test --no-pub --reporter=compact \
    --dart-define=PHP_RESPONSE_MODE=false \
    test/core/network/php/php_envelope_test.dart
run_check "Root optional-integration isolation" check_root_optional_isolation

if [[ "$MODE" == "full" || "$MODE" == "release" ]]; then
  run_check "Generated-source reproducibility" \
    scripts/check_codegen_reproducibility.sh
  for package in \
    app_notifications app_remote_config app_webview app_maps app_socket; do
    require_resolution "packages/$package"
    run_check "$package analyzer" analyze_optional_package "$package"
    run_check "$package tests" test_optional_package "$package"
  done
  for package in app_webview app_maps app_remote_config; do
    require_resolution "packages/$package/example"
    run_check "$package example analyzer" analyze_optional_example "$package"
    run_check "$package example tests" test_optional_example "$package"
  done
fi

if ((BUILD_RELEASES)); then
  build_release_matrix
  run_check "Optional Maps Android production example" \
    bash -c 'cd packages/app_maps/example && "$1" build apk --debug --flavor production --target-platform android-arm64' \
      _ "$FLUTTER_BIN"
  run_check "Reclaim optional Maps Android intermediates" \
    clean_optional_example_build app_maps
  run_check "Optional Remote Config Android production example" \
    bash -c 'cd packages/app_remote_config/example && "$1" build apk --debug --flavor production --target-platform android-arm64' \
      _ "$FLUTTER_BIN"
  run_check "Reclaim optional Remote Config Android intermediates" \
    clean_optional_example_build app_remote_config
  if [[ "$(uname -s)" == "Darwin" ]]; then
    run_check "Optional Maps iOS production example" \
      bash -c 'cd packages/app_maps/example && "$1" build ios --simulator --flavor production' \
        _ "$FLUTTER_BIN"
    run_check "Reclaim optional Maps iOS intermediates" \
      clean_optional_example_build app_maps
    run_check "Optional Remote Config iOS production example" \
      bash -c 'cd packages/app_remote_config/example && "$1" build ios --simulator --flavor production' \
        _ "$FLUTTER_BIN"
    run_check "Reclaim optional Remote Config iOS intermediates" \
      clean_optional_example_build app_remote_config
  fi
  run_check "Restore release evidence" restore_release_evidence
fi

if [[ "$MODE" == "release" ]]; then
  check_release_artifacts
fi

CURRENT_CHECK="complete"
echo "QUALITY GATE PASSED: mode=$MODE checks=$PASSED_CHECKS skipped=$SKIPPED_CHECKS builds=$BUILD_RELEASES"
