#!/usr/bin/env bash
cat <<'TXT'
Manual approval steps (Gatekeeper) — do this once after moving app to /Applications:

1) In Finder, navigate to /Applications
2) Right-click Cinderella.app -> Open
3) In the dialog that appears, click 'Open' to approve this app for future launches

If you prefer CLI, run (may require admin password):
  sudo xattr -rc /Applications/Cinderella.app
  sudo spctl --add /Applications/Cinderella.app
  sudo spctl --assess -v /Applications/Cinderella.app

After approval, run the app and check these files for diagnostics:
  ~/Desktop/cinderella_status.txt
  /tmp/cinderella.log
  ~/cinderella_stdout.log

TXT
