# Changelog

All notable changes to Flashback will be documented in this file.

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
