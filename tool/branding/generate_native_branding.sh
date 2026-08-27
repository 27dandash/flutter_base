#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIR="$ROOT_DIR/tool/branding"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

command -v sips >/dev/null 2>&1 || {
  echo "sips is required to regenerate the native placeholder assets." >&2
  exit 1
}

MASTER_JPEG="$TMP_DIR/neutral_app_icon.jpg"
MASTER_MARK="$TMP_DIR/neutral_launch_mark.png"
sips -s format jpeg -s formatOptions 100 \
  "$SOURCE_DIR/neutral_app_icon.svg" --out "$MASTER_JPEG" >/dev/null
sips -s format png "$SOURCE_DIR/neutral_launch_mark.svg" \
  --out "$MASTER_MARK" >/dev/null

write_icon() {
  local size="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  sips -z "$size" "$size" -s format png "$MASTER_JPEG" \
    --out "$destination" >/dev/null
}

write_mark() {
  local size="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  sips -z "$size" "$size" -s format png "$MASTER_MARK" \
    --out "$destination" >/dev/null
}

ANDROID_RES="$ROOT_DIR/android/app/src/main/res"
write_icon 48 "$ANDROID_RES/mipmap-mdpi/ic_launcher.png"
write_icon 72 "$ANDROID_RES/mipmap-hdpi/ic_launcher.png"
write_icon 96 "$ANDROID_RES/mipmap-xhdpi/ic_launcher.png"
write_icon 144 "$ANDROID_RES/mipmap-xxhdpi/ic_launcher.png"
write_icon 192 "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png"

for example in app_maps app_remote_config; do
  EXAMPLE_RES="$ROOT_DIR/packages/$example/example/android/app/src/main/res"
  write_icon 48 "$EXAMPLE_RES/mipmap-mdpi/ic_launcher.png"
  write_icon 72 "$EXAMPLE_RES/mipmap-hdpi/ic_launcher.png"
  write_icon 96 "$EXAMPLE_RES/mipmap-xhdpi/ic_launcher.png"
  write_icon 144 "$EXAMPLE_RES/mipmap-xxhdpi/ic_launcher.png"
  write_icon 192 "$EXAMPLE_RES/mipmap-xxxhdpi/ic_launcher.png"
  resources=(
    values/colors.xml
    values-night/colors.xml
    values/styles.xml
    values-night/styles.xml
    values-v31/styles.xml
    values-night-v31/styles.xml
    drawable/launch_background.xml
    drawable-v21/launch_background.xml
    drawable/ic_launcher_foreground.xml
    drawable/ic_launcher_monochrome.xml
    drawable/neutral_launch_mark.xml
    drawable/ic_notification.xml
    mipmap-anydpi-v26/ic_launcher.xml
    mipmap-anydpi-v33/ic_launcher.xml
  )
  for resource in "${resources[@]}"; do
    mkdir -p "$EXAMPLE_RES/$(dirname "$resource")"
    cp "$ANDROID_RES/$resource" "$EXAMPLE_RES/$resource"
  done
done
IOS_ICONS="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
write_icon 40 "$IOS_ICONS/Icon-App-20x20@2x.png"
write_icon 60 "$IOS_ICONS/Icon-App-20x20@3x.png"
write_icon 29 "$IOS_ICONS/Icon-App-29x29@1x.png"
write_icon 58 "$IOS_ICONS/Icon-App-29x29@2x.png"
write_icon 87 "$IOS_ICONS/Icon-App-29x29@3x.png"
write_icon 80 "$IOS_ICONS/Icon-App-40x40@2x.png"
write_icon 120 "$IOS_ICONS/Icon-App-40x40@3x.png"
write_icon 120 "$IOS_ICONS/Icon-App-60x60@2x.png"
write_icon 180 "$IOS_ICONS/Icon-App-60x60@3x.png"
write_icon 20 "$IOS_ICONS/Icon-App-20x20@1x.png"
write_icon 40 "$IOS_ICONS/Icon-App-20x20@2x.png"
write_icon 29 "$IOS_ICONS/Icon-App-29x29@1x.png"
write_icon 58 "$IOS_ICONS/Icon-App-29x29@2x.png"
write_icon 40 "$IOS_ICONS/Icon-App-40x40@1x.png"
write_icon 80 "$IOS_ICONS/Icon-App-40x40@2x.png"
write_icon 76 "$IOS_ICONS/Icon-App-76x76@1x.png"
write_icon 152 "$IOS_ICONS/Icon-App-76x76@2x.png"
write_icon 167 "$IOS_ICONS/Icon-App-83.5x83.5@2x.png"
write_icon 1024 "$IOS_ICONS/Icon-App-1024x1024@1x.png"

IOS_MARK="$ROOT_DIR/ios/Runner/Assets.xcassets/LaunchMark.imageset"
write_mark 128 "$IOS_MARK/LaunchMark.png"
write_mark 256 "$IOS_MARK/LaunchMark@2x.png"
write_mark 384 "$IOS_MARK/LaunchMark@3x.png"

for example in app_maps app_remote_config; do
  EXAMPLE_RUNNER="$ROOT_DIR/packages/$example/example/ios/Runner"
  EXAMPLE_ICONS="$EXAMPLE_RUNNER/Assets.xcassets/AppIcon.appiconset"
  write_icon 40 "$EXAMPLE_ICONS/Icon-App-20x20@2x.png"
  write_icon 60 "$EXAMPLE_ICONS/Icon-App-20x20@3x.png"
  write_icon 29 "$EXAMPLE_ICONS/Icon-App-29x29@1x.png"
  write_icon 58 "$EXAMPLE_ICONS/Icon-App-29x29@2x.png"
  write_icon 87 "$EXAMPLE_ICONS/Icon-App-29x29@3x.png"
  write_icon 80 "$EXAMPLE_ICONS/Icon-App-40x40@2x.png"
  write_icon 120 "$EXAMPLE_ICONS/Icon-App-40x40@3x.png"
  write_icon 120 "$EXAMPLE_ICONS/Icon-App-60x60@2x.png"
  write_icon 180 "$EXAMPLE_ICONS/Icon-App-60x60@3x.png"
  write_icon 20 "$EXAMPLE_ICONS/Icon-App-20x20@1x.png"
  write_icon 40 "$EXAMPLE_ICONS/Icon-App-20x20@2x.png"
  write_icon 29 "$EXAMPLE_ICONS/Icon-App-29x29@1x.png"
  write_icon 58 "$EXAMPLE_ICONS/Icon-App-29x29@2x.png"
  write_icon 40 "$EXAMPLE_ICONS/Icon-App-40x40@1x.png"
  write_icon 80 "$EXAMPLE_ICONS/Icon-App-40x40@2x.png"
  write_icon 76 "$EXAMPLE_ICONS/Icon-App-76x76@1x.png"
  write_icon 152 "$EXAMPLE_ICONS/Icon-App-76x76@2x.png"
  write_icon 167 "$EXAMPLE_ICONS/Icon-App-83.5x83.5@2x.png"
  write_icon 1024 "$EXAMPLE_ICONS/Icon-App-1024x1024@1x.png"

  EXAMPLE_MARK="$EXAMPLE_RUNNER/Assets.xcassets/LaunchMark.imageset"
  mkdir -p "$EXAMPLE_MARK"
  cp "$ROOT_DIR/ios/Runner/Assets.xcassets/LaunchMark.imageset/Contents.json" "$EXAMPLE_MARK/Contents.json"
  write_mark 128 "$EXAMPLE_MARK/LaunchMark.png"
  write_mark 256 "$EXAMPLE_MARK/LaunchMark@2x.png"
  write_mark 384 "$EXAMPLE_MARK/LaunchMark@3x.png"
  mkdir -p "$EXAMPLE_RUNNER/Assets.xcassets/LaunchBackground.colorset"
  cp "$ROOT_DIR/ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json" "$EXAMPLE_RUNNER/Assets.xcassets/LaunchBackground.colorset/Contents.json"
  cp "$ROOT_DIR/ios/Runner/Base.lproj/LaunchScreen.storyboard" "$EXAMPLE_RUNNER/Base.lproj/LaunchScreen.storyboard"
done

write_icon 192 "$ROOT_DIR/web/icons/Icon-192.png"
write_icon 512 "$ROOT_DIR/web/icons/Icon-512.png"
write_icon 192 "$ROOT_DIR/web/icons/Icon-maskable-192.png"
write_icon 512 "$ROOT_DIR/web/icons/Icon-maskable-512.png"
write_icon 32 "$ROOT_DIR/web/favicon.png"

MAC_ICONS="$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 64 128 256 512 1024; do
  write_icon "$size" "$MAC_ICONS/app_icon_${size}.png"
done

sips -z 256 256 -s format ico "$MASTER_JPEG" \
  --out "$ROOT_DIR/windows/runner/resources/app_icon.ico" >/dev/null

echo "Generated neutral Android, iOS, web, macOS, and Windows branding assets."
