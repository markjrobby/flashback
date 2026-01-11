Uninstall Flashback hooks and commands from Claude Code.

**Step 1: Remove hooks**

Read the file ~/.claude/settings.json.

Remove ONLY hooks where the command path ends with exactly:
- `/flashback/scripts/capture.sh`
- `/flashback/scripts/inject.sh`

Do NOT remove any other hooks.

Show the user exactly which hooks will be removed before making changes. Ask for confirmation.

Write the updated settings back to ~/.claude/settings.json.

**Step 2: Remove slash commands**

Delete these files if they exist:
- ~/.claude/commands/flashback-version.md
- ~/.claude/commands/flashback-update.md
- ~/.claude/commands/flashback-uninstall.md

**Step 3: Ask about data**

Ask the user if they also want to delete the stored flashback data at ~/.flashback. If yes, delete that directory.

**Step 4: Confirm**

Tell the user that Flashback has been uninstalled.
