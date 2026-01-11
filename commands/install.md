Install Flashback hooks and commands into Claude Code user settings.

**Step 1: Install hooks**

Read the file ~/.claude/settings.json (create it if it doesn't exist with empty JSON {}).

Add the following hooks to the settings, merging with any existing hooks:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Read|Bash|Grep|Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/flashback/scripts/capture.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/flashback/scripts/inject.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Write the updated settings back to ~/.claude/settings.json.

**Step 2: Install slash commands**

Create the directory ~/.claude/commands/ if it doesn't exist.

Copy the following command files from ~/flashback/commands/ to ~/.claude/commands/:
- Copy `~/flashback/commands/version.md` to `~/.claude/commands/flashback-version.md`
- Copy `~/flashback/commands/update.md` to `~/.claude/commands/flashback-update.md`
- Copy `~/flashback/commands/uninstall.md` to `~/.claude/commands/flashback-uninstall.md`

**Step 3: Confirm**

Tell the user:
- Flashback has been installed
- Hooks are active in all future Claude Code sessions
- Available commands: /flashback-version, /flashback-update, /flashback-uninstall
