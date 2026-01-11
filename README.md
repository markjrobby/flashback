# Flashback

**Visual memory for Claude Code sessions.**

**Current version:** 0.2.3 (2025-01-08) - [Changelog](CHANGELOG.md)

Flashback preserves old tool outputs as images before compaction loses them. When Claude's context gets summarized, you keep the full visual record.

## The Problem

Long Claude Code sessions accumulate context. Eventually, compaction kicks in and old outputs get summarized—**Claude decides what's important, and the original is lost forever.**

## The Solution

Flashback:
1. **Captures** large tool outputs (file reads, bash commands, grep results)
2. **Renders** them as images after N turns
3. **Injects** image paths before each prompt as visual memory

Unlike text summarization, images preserve **everything literally**—just compressed visually.

## Requirements

- **macOS only** (uses `qlmanage` for image rendering)
- **Node.js** (already required by Claude Code)
- No additional dependencies

## Installation

**1. Clone the plugin:**

```bash
git clone https://github.com/markjrobby/flashback.git ~/flashback
```

**2. Start Claude Code with the plugin and run the install command:**

```bash
claude --plugin-dir ~/flashback
```

Then inside Claude Code:

```
/flashback:install
```

**Done!** Flashback is now active for all future Claude Code sessions.

## Uninstall

Inside any Claude Code session with the plugin loaded:

```
/flashback:uninstall
```

Or manually remove the hooks from `~/.claude/settings.json` and delete:

```bash
rm -rf ~/flashback ~/.flashback
```

## How It Works

**Two hooks (pure bash + Node.js):**

1. `PostToolUse` (capture.sh) - Silently saves large outputs from Read, Bash, Grep, Glob
2. `UserPromptSubmit` (inject.sh) - Before each prompt, renders old captures as PNG images

**Rendering:** Uses macOS `qlmanage` to convert HTML → PNG (zero dependencies)

**Storage:** `~/.flashback/{session_id}/`

## Updates

Flashback auto-updates by default. On each new session, it checks GitHub for the latest version and pulls automatically.

To disable auto-updates:
```bash
export FLASHBACK_AUTO_UPDATE=false
```

To manually update:
```
/flashback:update
```

## Configuration

Environment variables (optional):

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASHBACK_AUTO_UPDATE` | `true` | Auto-update on session start |
| `FLASHBACK_MIN_CHARS` | `1000` | Min chars to capture |
| `FLASHBACK_TURNS_THRESHOLD` | `5` | Turns before rendering to image |
| `FLASHBACK_MAX_IMAGES` | `3` | Max images to render per prompt |
| `FLASHBACK_STORE_DIR` | `~/.flashback` | Storage location |

## Example

```
You: Read the auth.py file
Claude: [reads file - Flashback captures it silently]

You: Run the tests
Claude: [runs tests - Flashback captures output]

... 5 more turns ...

You: What was that bug in auth.py again?

[Flashback injects before prompt:]
[flashback] Visual memory from earlier:
  /src/auth.py (7 turns ago): ~/.flashback/abc123/001.png
  pytest output (6 turns ago): ~/.flashback/abc123/002.png

Claude: [Can now reference the images to recall exact details]
```

## Cleanup

Old sessions accumulate in `~/.flashback/`. Clean up periodically:

```bash
# Remove sessions older than 7 days
find ~/.flashback -type d -mtime +7 -exec rm -rf {} +
```

## License

MIT
