Gatekeeper troubleshooting for Cinderella

Why this matters
- On macOS, Gatekeeper may block locally-built or unsigned apps. If spctl reports 'rejected', the app will run but may not display UI like a status-bar item until the user explicitly approves it.

Fast user-approved flow (recommended)
1) Move the built app to /Applications (scripts/make_app.sh creates dist/Cinderella.app). 
2) In Finder, right-click /Applications/Cinderella.app → Open. In the dialog, click 'Open'. This registers an exception and permits future launches.

CLI helper scripts (provided)
- scripts/approve_instructions.sh: prints step-by-step instructions for manual approval.
- scripts/try_trust.sh: attempts to remove common extended attributes and add an spctl exception (uses sudo). Use with care; requires admin password.

Files to check after approval
- ~/Desktop/cinderella_status.txt  (App writes UI state diagnostics)
- /tmp/cinderella.log              (runtime markers/logs)
- ~/cinderella_stdout.log          (captured stdout when started from script)

If problems persist
- Consider signing with an Apple Developer ID certificate and re-building a signed installer. This requires an Apple Developer account and private key.
- If you want, I can prepare a signing script and instructions — you'll need to provide access to a valid Developer ID or run the signing step locally.
