#!/bin/bash
#
# Flashback Installer
# One-line install: curl -fsSL https://raw.githubusercontent.com/markjrobby/flashback/main/install.sh | bash
#

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}Installing Flashback...${NC}"

# 1. Clone or update repo
if [ -d ~/flashback ]; then
  echo "Updating existing installation..."
  cd ~/flashback && git pull --quiet origin main
else
  echo "Cloning flashback..."
  git clone --quiet https://github.com/markjrobby/flashback.git ~/flashback
fi

# 2. Create ~/.claude directories if needed
mkdir -p ~/.claude/commands

# 3. Add hooks to settings.json
SETTINGS_FILE=~/.claude/settings.json

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Use node to merge hooks into settings
node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));

if (!settings.hooks) settings.hooks = {};
if (!settings.hooks.PostToolUse) settings.hooks.PostToolUse = [];
if (!settings.hooks.UserPromptSubmit) settings.hooks.UserPromptSubmit = [];

// Remove any existing flashback hooks
settings.hooks.PostToolUse = settings.hooks.PostToolUse.filter(h =>
  !h.hooks?.some(hh => hh.command?.includes('flashback'))
);
settings.hooks.UserPromptSubmit = settings.hooks.UserPromptSubmit.filter(h =>
  !h.hooks?.some(hh => hh.command?.includes('flashback'))
);

// Add flashback hooks
settings.hooks.PostToolUse.push({
  matcher: 'Read|Bash|Grep|Glob',
  hooks: [{
    type: 'command',
    command: '~/flashback/scripts/capture.sh',
    timeout: 10
  }]
});

settings.hooks.UserPromptSubmit.push({
  matcher: '.*',
  hooks: [{
    type: 'command',
    command: '~/flashback/scripts/inject.sh',
    timeout: 30
  }]
});

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
"

# 4. Copy slash commands
cp ~/flashback/commands/version.md ~/.claude/commands/flashback-version.md
cp ~/flashback/commands/update.md ~/.claude/commands/flashback-update.md
cp ~/flashback/commands/uninstall.md ~/.claude/commands/flashback-uninstall.md

echo -e "${GREEN}Flashback installed successfully!${NC}"
echo ""
echo "Available commands:"
echo "  /flashback-version   - Check current version"
echo "  /flashback-update    - Update to latest version"
echo "  /flashback-uninstall - Remove flashback"
echo ""
echo "Flashback will be active in all new Claude Code sessions."
