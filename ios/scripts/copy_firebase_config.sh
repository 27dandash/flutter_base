#!/bin/sh
set -eu

case "${CONFIGURATION}" in
  *development*) FLAVOR="development" ;;
  *staging*) FLAVOR="staging" ;;
  *production*) FLAVOR="production" ;;
  *)
    echo "No Firebase flavor mapped for configuration: ${CONFIGURATION}"
    exit 0
    ;;
esac

SOURCE_PLIST="${PROJECT_DIR}/Runner/Firebase/${FLAVOR}/GoogleService-Info.plist"
DESTINATION_PLIST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

if [ ! -f "${SOURCE_PLIST}" ]; then
  echo "No optional Firebase plist at ${SOURCE_PLIST}; skipping."
  exit 0
fi

if grep -q '{{' "${SOURCE_PLIST}"; then
  echo "Firebase template placeholders must be replaced for ${FLAVOR}." >&2
  exit 2
fi

cp "${SOURCE_PLIST}" "${DESTINATION_PLIST}"
echo "Installed Firebase config for ${FLAVOR}."
