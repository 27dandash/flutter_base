#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/flutter-base-codegen.XXXXXX")"
trap 'find "$TEMP_ROOT" -depth -delete 2>/dev/null || true' EXIT

configured_sdk=""
while IFS='=' read -r key value; do
  if [[ "$key" == "flutter.sdk" ]]; then
    configured_sdk="$value"
    break
  fi
done < "$PROJECT_ROOT/android/local.properties"
DART_BIN="$configured_sdk/bin/dart"
[[ -x "$DART_BIN" ]] || {
  echo "Configured Dart SDK is unavailable." >&2
  exit 2
}
[[ -f "$PROJECT_ROOT/.dart_tool/package_config.json" ]] || {
  echo "Root dependency resolution is missing; run flutter pub get first." >&2
  exit 2
}

mkdir -p "$TEMP_ROOT/project/.dart_tool" "$TEMP_ROOT/project/tool"
cp "$PROJECT_ROOT/pubspec.yaml" "$PROJECT_ROOT/pubspec.lock" \
  "$TEMP_ROOT/project/"
cp "$PROJECT_ROOT/.dart_tool/package_config.json" \
  "$PROJECT_ROOT/.dart_tool/package_graph.json" \
  "$TEMP_ROOT/project/.dart_tool/"
cp "$PROJECT_ROOT/tool/generate_locale_keys.dart" "$TEMP_ROOT/project/tool/"
cp -R "$PROJECT_ROOT/lib" "$PROJECT_ROOT/assets" "$TEMP_ROOT/project/"

(
  cd "$TEMP_ROOT/project"
  "$DART_BIN" run build_runner build
  "$DART_BIN" run tool/generate_locale_keys.dart
  "$DART_BIN" format lib/src/config/language/locale_keys.g.dart >/dev/null
)

generated_manifest() {
  local root="$1"
  (
    cd "$root"
    find lib -type f \
      \( -name '*.g.dart' -o -name '*.gen.dart' -o -name '*.config.dart' \) \
      -print0 | sort -z | xargs -0 shasum
  )
}

generated_manifest "$PROJECT_ROOT" > "$TEMP_ROOT/expected.sha1"
generated_manifest "$TEMP_ROOT/project" > "$TEMP_ROOT/generated.sha1"
if ! diff -u "$TEMP_ROOT/expected.sha1" "$TEMP_ROOT/generated.sha1"; then
  echo "Generated source is not reproducible. Run the documented generators and review the result." >&2
  exit 1
fi

echo "Code generation reproducible: build_runner, Injectable/Hive/FlutterGen, and 83 AR/EN keys."
