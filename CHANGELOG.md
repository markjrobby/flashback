# Changelog

All notable changes to Flashback will be documented in this file.

## [0.3.0] - 2025-01-11

### Added
- One-line install script: `curl -fsSL https://raw.githubusercontent.com/markjrobby/flashback/main/install.sh | bash`
- Automatic hook configuration during install (no manual steps needed)

### Changed
- Installation now clones to `~/flashback` instead of requiring manual plugin setup
- Simplified UX: install once, works in all sessions automatically

## [0.2.4] - 2025-01-08

### Changed
- `/flashback:install` now also installs slash commands to `~/.claude/commands/`
- Slash commands renamed: `/flashback-version`, `/flashback-update`, `/flashback-uninstall`
- Commands now work in all sessions without needing `--plugin-dir`

## [0.2.3] - 2025-01-08

### Fixed
- Auto-update notification now shows even when no captures exist yet
- Restructured inject script to not exit early before outputting update messages

## [0.2.2] - 2025-01-08

### Changed
- Use JSON output with `systemMessage` for user-visible notifications
- Notifications now properly display in Claude Code UI

## [0.2.1] - 2025-01-08

### Added
- `/flashback:version` command to check current and latest version

## [0.2.0] - 2025-01-08

### Added
- Auto-update: Checks GitHub for latest version on session start and pulls automatically
- `FLASHBACK_AUTO_UPDATE` env var to disable auto-updates (default: `true`)
- `/flashback:update` command for manual updates
- Version display in notification: `[flashback v0.2.0]`
- Test suite with 7 tests

### Changed
- Notification now shows on every prompt (not just when new images are rendered)
- Notification displayed in cyan for better visibility

### Fixed
- Delimiter parsing for hints containing pipe (`|`) characters

## [0.1.0] - 2025-01-08

### Added
- Initial release
- `capture.sh` hook to save large tool outputs (Read, Bash, Grep, Glob)
- `inject.sh` hook to render old context as PNG images
- `/flashback:install` and `/flashback:uninstall` commands
- Zero dependencies on macOS (uses `qlmanage` + Node.js)
