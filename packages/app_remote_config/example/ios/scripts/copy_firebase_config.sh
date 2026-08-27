#!/bin/sh
set -eu

case "$(printf '%s' "${CONFIGURATION:-}" | tr '[:upper:]' '[:lower:]')" in
  *development*) flavor=development ;;
  *staging*) flavor=staging ;;
  *) flavor=production ;;
esac

source_file="${SRCROOT}/Runner/Firebase/${flavor}/GoogleService-Info.plist"
destination="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

if [ ! -f "${source_file}" ]; then
  echo "warning: Firebase config is absent for ${flavor}; the optional example remains disabled."
  exit 0
fi

if grep -q '{{' "${source_file}"; then
  echo "error: Firebase template placeholders must be replaced for ${flavor}." >&2
  exit 2
fi

cp "${source_file}" "${destination}"
