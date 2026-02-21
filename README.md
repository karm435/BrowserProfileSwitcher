# Browser Profile Switcher

A lightweight macOS menu bar app to quickly switch between browser profiles across multiple Chromium-based browsers.

## Features

- **Menu bar app** - lives in your menu bar, no dock icon clutter
- **7 supported browsers** - Google Chrome, Brave, Microsoft Edge, Vivaldi, Arc, Opera, and Chromium
- **Auto-detection** - automatically discovers installed browsers and their profiles
- **Global keyboard shortcuts** - switch profiles from anywhere with customizable hotkeys
- **Quick launch** - open any of your first 9 profiles with Cmd+Option+1 through 9
- **Launch at login** - optionally start the app when you log in
- **Per-browser toggle** - enable or disable browsers you don't want to see

## Installation

1. Download `BrowserProfileSwitcher.dmg` from the [latest release](https://github.com/karm435/BrowserProfileSwitcher/releases/latest)
2. Open the DMG and drag **Browser Profile Switcher** to your **Applications** folder
3. Launch the app from Applications - it will appear in your menu bar

## Usage

Click the menu bar icon to see all your browser profiles grouped by browser. Click a profile to launch it.

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+Option+P | Toggle the menu |
| Cmd+Option+1-9 | Quick launch profiles |
| Cmd+R | Refresh profiles |
| Cmd+, | Open settings |

All shortcuts are customizable in Settings > Keyboard.

### Settings

- **General** - Launch at login toggle
- **Keyboard** - Customize all keyboard shortcuts
- **Browsers** - Enable/disable individual browsers

## Requirements

- macOS 14.0 or later

## Building from Source

1. Clone the repository
2. Open `ChromeProfile.xcodeproj` in Xcode
3. Build and run (Cmd+R)

The project uses [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) as its only dependency, which is resolved automatically via Swift Package Manager.

## License

This project is proprietary software. Redistribution, modification, and commercial use require prior written permission. See [LICENSE](LICENSE) for details.
