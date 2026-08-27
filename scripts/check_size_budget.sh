#!/usr/bin/env bash
set -euo pipefail

ARM64_APK="${1:-build/app/outputs/flutter-apk/app-production-release.apk}"
AAB="${2:-build/app/outputs/bundle/productionRelease/app-production-release.aab}"

# Audited on Flutter 3.47.1 / Dart 3.13.1 with --split-debug-info. Budgets
# allow 512 KiB ARM64 growth and 1 MiB AAB growth before baseline review.
ARM64_BASELINE_BYTES=18816110
ARM64_MAX_BYTES=19340398
AAB_BASELINE_BYTES=50618227
AAB_MAX_BYTES=51666803
SOURCE_ASSETS_MAX_BYTES=2100000

check_file() {
  local label="$1"
  local path="$2"
  local maximum="$3"

  if [[ ! -f "$path" ]]; then
    echo "Missing $label artifact: $path" >&2
    exit 2
  fi

  local actual
  actual="$(wc -c < "$path" | tr -d ' ')"
  echo "$label: $actual bytes (budget $maximum)"
  if ((actual > maximum)); then
    echo "$label exceeds its audited size budget by $((actual - maximum)) bytes." >&2
    exit 1
  fi
}

check_file "ARM64 APK" "$ARM64_APK" "$ARM64_MAX_BYTES"
check_file "Production AAB" "$AAB" "$AAB_MAX_BYTES"

asset_bytes=0
while IFS= read -r -d '' asset; do
  bytes="$(wc -c < "$asset" | tr -d ' ')"
  asset_bytes=$((asset_bytes + bytes))
done < <(find assets -type f -print0)
echo "Source assets: $asset_bytes bytes (budget $SOURCE_ASSETS_MAX_BYTES)"
if ((asset_bytes > SOURCE_ASSETS_MAX_BYTES)); then
  echo "Source assets exceed the audited budget by $((asset_bytes - SOURCE_ASSETS_MAX_BYTES)) bytes." >&2
  exit 1
fi

# bundletool/DevTools values are supplied by a measurement job when available.
# They are not guessed from the upload artifact because those units differ.
check_optional_metric() {
  local label="$1"
  local value="$2"
  local maximum="$3"
  if [[ -z "$value" ]]; then
    echo "$label: not supplied (documented budget $maximum bytes)"
    return
  fi
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "$label must be an integer byte count, got: $value" >&2
    exit 2
  fi
  echo "$label: $value bytes (budget $maximum)"
  if ((value > maximum)); then
    echo "$label exceeds its audited size budget by $((value - maximum)) bytes." >&2
    exit 1
  fi
}

check_optional_metric \
  "Estimated ARM64 Play download" "${ESTIMATED_DOWNLOAD_BYTES:-}" 9772234
check_optional_metric "Dart AOT" "${DART_AOT_BYTES:-}" 5309320
check_optional_metric \
  "ARM64 engine/plugin native libraries" "${NATIVE_LIBRARY_BYTES:-}" 12010560

echo "Size budget passed. Baselines: ARM64=$ARM64_BASELINE_BYTES, AAB=$AAB_BASELINE_BYTES."
