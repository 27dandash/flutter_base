#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:?Usage: check_optional_resolution.sh <package-directory-name>}"
case "$PACKAGE" in
  app_notifications|app_remote_config|app_webview|app_maps|app_socket) ;;
  *) echo "Unsupported optional package: $PACKAGE" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/clean-arch-optional-resolution.XXXXXX")"
trap 'find "$TEMP" -depth -delete 2>/dev/null || true' EXIT

configured_sdk=""
while IFS='=' read -r key value || [[ -n "$key" ]]; do
  if [[ "$key" == "flutter.sdk" ]]; then
    configured_sdk="$value"
    break
  fi
done < "$ROOT/android/local.properties" 2>/dev/null || true
if [[ -n "$configured_sdk" && -x "$configured_sdk/bin/flutter" ]]; then
  FLUTTER_BIN="$configured_sdk/bin/flutter"
else
  # local.properties is generated and git-ignored; fall back to PATH.
  FLUTTER_BIN="$(command -v flutter || true)"
fi
[[ -n "$FLUTTER_BIN" && -x "$FLUTTER_BIN" ]] || {
  echo "Configured Flutter SDK is unavailable." >&2
  exit 2
}

awk -v package="$PACKAGE" -v package_path="$ROOT/packages/$PACKAGE" '
  /^dev_dependencies:/ && !inserted {
    print "  " package ":"
    print "    path: " package_path
    inserted = 1
  }
  { print }
' "$ROOT/pubspec.yaml" > "$TEMP/pubspec.yaml"

"$FLUTTER_BIN" pub get --directory "$TEMP"
echo "Root + $PACKAGE dependency graph resolves."
