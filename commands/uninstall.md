Uninstall Flashback hooks from Claude Code user settings.

Read the file ~/.claude/settings.json.

Remove ONLY hooks where the command path ends with exactly:
- `/flashback/scripts/capture.sh`
- `/flashback/scripts/inject.sh`

Do NOT remove any other hooks, even if they contain the word "flashback" elsewhere.

Show the user exactly which hooks will be removed before making changes. Ask for confirmation.

Write the updated settings back to ~/.claude/settings.json.

Ask the user if they also want to delete the stored flashback data at ~/.flashback. If yes, delete that directory.

Confirm to the user that Flashback has been uninstalled.
