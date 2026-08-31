#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

fail() {
  echo "IDENTITY AUDIT FAILED: $*" >&2
  exit 1
}

require_text() {
  local path="$1"
  local pattern="$2"
  grep -Eq "$pattern" "$path" ||
    fail "$path is missing expected identity/configuration: $pattern"
}

require_file() {
  [[ -f "$1" ]] || fail "required file is missing: $1"
}

[[ "$(basename "$PROJECT_ROOT")" == "flutter_base" ]] ||
  fail "project directory must be named flutter_base"
require_text pubspec.yaml '^name: flutter_base$'

android_gradle=android/app/build.gradle.kts
require_text "$android_gradle" 'namespace = "com\.flutter\.newproject"'
require_text "$android_gradle" 'applicationId = "com\.flutter\.newproject"'
require_text "$android_gradle" 'applicationIdSuffix = "\.dev"'
require_text "$android_gradle" 'applicationIdSuffix = "\.staging"'
require_text "$android_gradle" 'Flutter Base Dev'
require_text "$android_gradle" 'Flutter Base Staging'
require_text "$android_gradle" '"Flutter Base"'
main_activity=android/app/src/main/kotlin/com/flutter/newproject/MainActivity.kt
require_text "$main_activity" '^package com\.flutter\.newproject$'

ios_project=ios/Runner.xcodeproj/project.pbxproj
ios_expected=(
  'com.flutter.newproject;'
  'com.flutter.newproject.dev;'
  'com.flutter.newproject.staging;'
  '"Flutter Base";'
  '"Flutter Base Dev";'
  '"Flutter Base Staging";'
)
for expected in "${ios_expected[@]}"; do
  grep -Fq "$expected" "$ios_project" ||
    fail "iOS flavor matrix is missing $expected"
done

native_resources=(
  android/app/src/main/res/values/styles.xml
  android/app/src/main/res/values-v31/styles.xml
  android/app/src/main/res/values-night-v31/styles.xml
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml
  android/app/src/main/res/drawable/ic_launcher_monochrome.xml
  ios/Runner/Base.lproj/LaunchScreen.storyboard
  ios/Runner/Assets.xcassets/LaunchMark.imageset/Contents.json
  ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
)
for resource in "${native_resources[@]}"; do
  require_file "$resource"
done
require_text ios/Runner/Base.lproj/LaunchScreen.storyboard 'image="LaunchMark"'
launch_image_catalogs="$(find ios packages/app_maps/example/ios packages/app_remote_config/example/ios -type d -name 'LaunchImage.imageset' -print -quit)"
[[ -z "$launch_image_catalogs" ]] ||
  fail "obsolete LaunchImage catalog remains active"

root_icon=ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
root_icon_sha="$(shasum -a 256 "$root_icon" | awk '{print $1}')"
example_icons=(
  packages/app_maps/example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
  packages/app_remote_config/example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
)
for icon in "${example_icons[@]}"; do
  require_file "$icon"
  [[ "$(shasum -a 256 "$icon" | awk '{print $1}')" == "$root_icon_sha" ]] ||
    fail "optional example icon differs from the neutral source: $icon"
done

maps_android=packages/app_maps/example/android/app/build.gradle.kts
maps_manifest=packages/app_maps/example/android/app/src/main/AndroidManifest.xml
maps_properties=packages/app_maps/example/android/maps.properties.example
maps_ios=packages/app_maps/example/ios
require_text "$maps_android" 'id\("kotlin-android"\)'
require_text "$maps_android" 'MAPS_API_KEY_'
require_text "$maps_properties" 'MAPS_API_KEY_DEVELOPMENT'
require_text "$maps_properties" 'MAPS_API_KEY_STAGING'
require_text "$maps_properties" 'MAPS_API_KEY_PRODUCTION'
require_text "$maps_manifest" 'com.google.android.geo.API_KEY'
require_text "$maps_ios/Runner/Info.plist" 'GOOGLE_MAPS_API_KEY'
require_text "$maps_ios/Runner/AppDelegate.swift" 'GMSServices.provideAPIKey'
for flavor in Development Staging Production; do
  require_file "$maps_ios/Flutter/Maps${flavor}.local.xcconfig.example"
done

firebase_android=packages/app_remote_config/example/android/app
firebase_ios=packages/app_remote_config/example/ios
require_text "$firebase_android/build.gradle.kts" 'id\("kotlin-android"\)'
for flavor in development staging production; do
  require_file "$firebase_android/src/$flavor/google-services.json.example"
  require_file "$firebase_ios/Runner/Firebase/$flavor/GoogleService-Info.plist.example"
done
require_file "$firebase_ios/scripts/copy_firebase_config.sh"

while IFS= read -r possible_secret; do
  case "$(basename "$possible_secret")" in
    maps.properties|google-services.json|GoogleService-Info.plist)
      fail "a real Maps/Firebase configuration file is present: $possible_secret"
      ;;
  esac
done < <(find packages/app_maps/example packages/app_remote_config/example -type f -print)

active_guidance=(
  AGENTS.md
  CLAUDE.md
  README.md
  .codex/skills/flutter-base-production/SKILL.md
  .claude/skills/flutter-base-production/SKILL.md
  .cursor/rules/00-flutter-base-production.mdc
  docs/prompts/AUTHORITATIVE_SPEC.md
)
old_guidance_pattern='flutter_clean_arch_base-main|com\.example\.clean(_arch_base|ArchBase)|Clean Arch([[:space:]]|$)|/Users/'
if grep -Eini "$old_guidance_pattern" "${active_guidance[@]}"; then
  fail "active guidance contains an obsolete identity or personal path"
fi

search_args=(
  -i
  -n
  --hidden
  --glob
  '!build/**'
  --glob
  '!.dart_tool/**'
  --glob
  '!coverage/**'
  --glob
  '!scripts/check_project_identity.sh'
  --glob
  '!docs/COMMAND_LOG_2026-08-27.md'
  --glob
  '!docs/FINAL_DEPENDENCY_LIVE_SKILLS_PROMPTS_REPORT.md'
  --glob
  '!docs/WIDGET_HARDENING_REPORT.md'
  --glob
  '!docs/CHANGE_MANIFEST.md'
  --glob
  '!docs/SIZE_AUDIT.md'
  --glob
  '!docs/TEST_COUNT_RECONCILIATION.md'
  --glob
  '!docs/CROSS_PROJECT_RECURRENCE.md'
  --glob
  '!docs/reports/**'
  --glob
  '!reports/**'
  --glob
  '!md/**'
)
old_identity_pattern='(أوامر[[:space:]_-]*الشبكة|aw+a?mer[[:space:]_-]*al[[:space:]_-]*shabaka|i[[:space:]_-]*craft|flutter_clean_arch_base-main|com\.example\.clean(_arch_base|ArchBase)|package:clean_arch_base)'
if rg "${search_args[@]}" "$old_identity_pattern"; then
  fail "active source contains old branding or identity"
fi

if rg -n 'DEVELOPMENT_TEAM = ' ios packages/app_maps/example/ios packages/app_remote_config/example/ios; then
  fail "template contains a personal Apple development team"
fi

echo "Identity audit passed: neutral Android/iOS flavors, icons, splash, Maps/Firebase templates, and active guidance."
