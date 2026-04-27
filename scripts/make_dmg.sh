#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/make_dmg.sh
# Builds Cinderella.app and packages it into dist/Cinderella.dmg

APP_NAME="Cinderella.app"
DMG_NAME="Cinderella.dmg"
DIST_DIR="dist"
APP_PATH="${DIST_DIR}/${APP_NAME}"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
STAGE_DIR="${DIST_DIR}/dmg-staging"

"$(dirname "$0")/make_app.sh"

if [ ! -d "${APP_PATH}" ]; then
  echo "ERROR: App not found at ${APP_PATH}"
  exit 1
fi

rm -rf "${STAGE_DIR}" "${DMG_PATH}"
mkdir -p "${STAGE_DIR}"

cp -R "${APP_PATH}" "${STAGE_DIR}/${APP_NAME}"
ln -s /Applications "${STAGE_DIR}/Applications"

hdiutil create \
  -volname "Cinderella" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

rm -rf "${STAGE_DIR}"

echo "Created ${DMG_PATH}"
