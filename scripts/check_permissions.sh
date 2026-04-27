#!/usr/bin/env bash
# Simple helper to guide granting macOS permissions for the app
# Usage: ./scripts/check_permissions.sh

APP_PATH="$(pwd)/dist/Cinderella.app"
BUNDLE_ID="com.yourcompany.Cinderella"

echo "App: ${APP_PATH}"

# Accessibility check using AppleScript: returns 0 when enabled for the current process (Terminal), but we can't check arbitrary app easily
osascript -e 'tell application "System Events" to (UI elements enabled)'

cat <<EOF

Manual steps to grant permissions:
1) Open System Settings -> Privacy & Security -> Accessibility -> click + and add: ${APP_PATH}
2) Open System Settings -> Privacy & Security -> Input Monitoring -> add ${APP_PATH}
3) (Optional) Screen Recording -> add ${APP_PATH}

After granting, quit and reopen the app.
EOF
