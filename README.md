# Cinderella

[한국어 문서 보기 (README.ko.md)](./README.ko.md)

Cinderella is a macOS menu bar app that gradually nudges you to go home when you keep working past your configured end-of-work time.

## Features
- Menu bar controls: `Start` / `Stop`
- Starts behavior based on configured work-end time (`HH:mm`)
- Status text/color update after work-end time
- Event toggles:
  - `hide_windows`
  - `fullscreen_warning`
  - `key_substitution`
  - `cursor_jitter`
- Emergency stop hotkey: `Cmd + Opt + Ctrl + Shift + Esc`

## Requirements
- macOS 12+
- Xcode Command Line Tools (`swift`, `hdiutil`)

## Quick Start (Dev)
```bash
swift build
open .build/debug/Cinderella
```

## Build .app Bundle
```bash
./scripts/make_app.sh
```

Output:
- `dist/Cinderella.app`

## Build DMG (for Distribution)
```bash
./scripts/make_dmg.sh
```

Output:
- `dist/Cinderella.dmg`

## End-user Installation
1. Open `Cinderella.dmg`
2. Drag `Cinderella.app` to `Applications`
3. Launch `/Applications/Cinderella.app`

## Required Permissions (macOS)
Go to `System Settings` -> `Privacy & Security`

1. `Accessibility`
- Add `Cinderella` and enable it

2. `Input Monitoring`
- Add `Cinderella` and enable it

After changing permissions, fully quit and relaunch the app.

## Basic Usage
1. Click Cinderella in the menu bar
2. Open `Preferences...`
   - `Work end time (HH:mm)`
   - `After work-end message`
3. Click `Start`
4. Toggle events from `Events` menu as needed
5. Stop with `Stop` or the emergency hotkey

## Status Text Rules
- Not working: `퇴근 HH:mm`
- Working + before work-end: `퇴근 HH:mm (근무중)`
- Working + after work-end: `퇴근 HH:mm (<configured message>)` in red

## Troubleshooting
### Menu bar text/icon not visible
- Disable auto-hide for menu bar
- Free menu bar space (too many icons can truncate items)
- Relaunch the app

### App still not working after granting permissions
- Toggle permissions off/on, then relaunch
- Gatekeeper guide:
  - `docs/GATEKEEPER.md`
  - `scripts/approve_instructions.sh`

## Scripts
- Build app bundle: `scripts/make_app.sh`
- Build DMG: `scripts/make_dmg.sh`
- Permission helper: `scripts/check_permissions.sh`

## Notice
This project is intended for demo/learning purposes. Review user consent, security, and legal requirements before production distribution.
