Update Flashback to the latest version.

1. First, read the current version from `~/flashback/.claude-plugin/plugin.json`

2. Run this command to pull the latest version:
```bash
cd ~/flashback && git pull origin main
```

3. Check the result:
   - If successful: Read the new version from `~/flashback/.claude-plugin/plugin.json` and tell the user "Flashback updated from vX.X.X to vY.Y.Y" (or "Flashback is already up to date at vX.X.X" if versions match)
   - If failed: Tell the user the update failed, show the error message, and suggest they check https://github.com/markjrobby/flashback for help or to report the issue
