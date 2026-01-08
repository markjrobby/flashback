Install Flashback hooks into Claude Code user settings.

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
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/capture.sh",
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
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/inject.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Write the updated settings back to ~/.claude/settings.json.

Confirm to the user that Flashback has been installed and will be active in all future Claude Code sessions.
