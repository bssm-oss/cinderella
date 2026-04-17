#!/usr/bin/env bash
set -euo pipefail

APP="/Applications/Cinderella.app"

echo "Helper: attempt to remediate Gatekeeper issues for ${APP}"

if [ ! -d "$APP" ]; then
  echo "App not found at ${APP}. Please move the built .app to /Applications and run again."
  exit 1
fi

echo "Listing extended attributes (xattr -l):"
xattr -l "$APP" || true

echo "Trying to remove common quarantine/provenance attributes (requires sudo)."
for attr in com.apple.quarantine com.apple.provenance com.apple.metadata:kMDItemWhereFroms; do
  echo "Removing $attr if present..."
  sudo xattr -d "$attr" "$APP" 2>/dev/null || true
done

echo "Re-checking xattr:"
xattr -l "$APP" || true

echo "Attempting to add spctl exception (may require sudo)."
if sudo spctl --add "$APP" 2>/dev/null; then
  echo "spctl --add succeeded"
else
  echo "spctl --add failed or returned non-zero. You can still allow via Finder: Right-click → Open and click 'Open' in the dialog."
fi

echo "spctl assessment (verbose):"
sudo spctl --assess -v "$APP" || true

cat <<EOF
Manual steps if the above didn't help:
 1) In Finder, right-click /Applications/Cinderella.app → Open → click Open in the dialog.
 2) If you prefer CLI, run these commands:
    sudo xattr -rc /Applications/Cinderella.app
    sudo spctl --add /Applications/Cinderella.app
    sudo spctl --assess -v /Applications/Cinderella.app
 3) After approving, open the app and check ~/Desktop/cinderella_status.txt and /tmp/cinderella.log
EOF
