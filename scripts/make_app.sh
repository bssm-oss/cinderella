#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/make_app.sh
# Builds release executable and creates a macOS .app bundle at ./dist/Cinderella.app

EXECUTABLE_NAME="Cinderella"
BUILD_CONFIG=release
BUILD_DIR=".build/${BUILD_CONFIG}"
APP_NAME="${EXECUTABLE_NAME}.app"
APP_DIR="dist/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_PLIST_PATH="${CONTENTS_DIR}/Info.plist"

echo "Building (swift build -c ${BUILD_CONFIG})..."
swift build -c ${BUILD_CONFIG}

if [ ! -x "${BUILD_DIR}/${EXECUTABLE_NAME}" ]; then
  echo "ERROR: Built executable not found: ${BUILD_DIR}/${EXECUTABLE_NAME}"
  exit 1
fi

# Clean previous bundle
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy executable
cp "${BUILD_DIR}/${EXECUTABLE_NAME}" "${MACOS_DIR}/${EXECUTABLE_NAME}"
chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"

# Copy project resources (if any) into app Resources
if [ -d "Sources/Cinderella/Resources" ]; then
  cp -R "Sources/Cinderella/Resources/"* "${RESOURCES_DIR}/" || true
fi

# Copy SwiftPM resource bundle when available
if [ -d "${BUILD_DIR}/Cinderella_Cinderella.bundle" ]; then
  cp -R "${BUILD_DIR}/Cinderella_Cinderella.bundle" "${RESOURCES_DIR}/"
fi

# Minimal Info.plist
cat > "${INFO_PLIST_PATH}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.yourcompany.${EXECUTABLE_NAME}</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <!-- Hide dock icon and make app agent (status bar only) -->
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will allow some permission flows in development
echo "Codesigning (ad-hoc)..."
codesign --force --sign - "${APP_DIR}" || true

cat > "${APP_DIR}/README_RUN.txt" <<TXT
Run the app (open the bundle):
  open "${APP_DIR}"

Required permissions (grant in System Settings -> Privacy & Security):
  - Accessibility: required for cursor warp, hiding/showing/moving other apps/windows, and many control APIs.
  - Input Monitoring: required on recent macOS versions to intercept global keyboard events (CGEventTap behavior).
  - Screen Recording: required if you add features that capture screen contents.

Grant these to the built app (dist/${APP_NAME}) and/or Terminal if you run the binary from Terminal.
TXT

echo "Created ${APP_DIR}"
echo "Next: open '${APP_DIR}' or move it to /Applications. Grant Accessibility/Input Monitoring in System Settings."
