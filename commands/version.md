Show the current Flashback version.

Read the version from `~/flashback/.claude-plugin/plugin.json` and display it to the user.

Also check if there's a newer version available on GitHub by fetching:
https://raw.githubusercontent.com/markjrobby/flashback/main/.claude-plugin/plugin.json

Compare the versions and tell the user:
- Current version: vX.X.X
- Latest version: vY.Y.Y (if different, suggest running `/flashback:update`)
- Or "You're up to date!" if versions match
