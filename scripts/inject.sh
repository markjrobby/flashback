#!/bin/bash
#
# Flashback - Inject Hook
# Renders old context as images and shows available visual memory
#

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
STORE_DIR="${FLASHBACK_STORE_DIR:-$HOME/.flashback}"
TURNS_THRESHOLD="${FLASHBACK_TURNS_THRESHOLD:-5}"
MAX_IMAGES="${FLASHBACK_MAX_IMAGES:-3}"
AUTO_UPDATE="${FLASHBACK_AUTO_UPDATE:-true}"

# Colors
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get local version from plugin.json
LOCAL_VERSION=$(node -e "
const fs = require('fs');
const p = JSON.parse(fs.readFileSync('$PLUGIN_DIR/.claude-plugin/plugin.json', 'utf8'));
console.log(p.version || '0.0.0');
" 2>/dev/null)

# Read JSON from stdin to temp file (avoids shell escaping issues)
TEMP_INPUT=$(mktemp)
cat > "$TEMP_INPUT"

# Extract session ID
SESSION_ID=$(node -e "
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('$TEMP_INPUT', 'utf8'));
console.log(input.session_id || '');
" 2>/dev/null)

rm -f "$TEMP_INPUT"

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

SESSION_DIR="$STORE_DIR/$SESSION_ID"

# Create session dir if it doesn't exist (for version check file)
mkdir -p "$SESSION_DIR"

# Version check - only once per session
VERSION_CHECK_FILE="$SESSION_DIR/.version_checked"
if [ ! -f "$VERSION_CHECK_FILE" ]; then
  touch "$VERSION_CHECK_FILE"

  # Fetch latest version from GitHub (with 2s timeout)
  REMOTE_VERSION=$(curl -s --max-time 2 \
    "https://raw.githubusercontent.com/markjrobby/flashback/main/.claude-plugin/plugin.json" 2>/dev/null | \
    node -e "
let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const p = JSON.parse(data);
    console.log(p.version || '');
  } catch(e) {
    console.log('');
  }
});
" 2>/dev/null)

  if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    # Compare versions (simple string compare works for semver)
    if [ "$(printf '%s\n' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -n1)" = "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
      if [ "$AUTO_UPDATE" = "true" ]; then
        # Auto-update: pull latest
        cd "$PLUGIN_DIR" && git pull --quiet origin main 2>/dev/null
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}[flashback] Updated to v$REMOTE_VERSION${NC}"
        else
          echo -e "${YELLOW}[flashback v$LOCAL_VERSION] Update available: v$REMOTE_VERSION - run /flashback:update${NC}"
        fi
      else
        echo -e "${YELLOW}[flashback v$LOCAL_VERSION] Update available: v$REMOTE_VERSION - run /flashback:update${NC}"
      fi
    fi
  fi
fi

# Check if we have any captured entries
if [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

# Count total entries (current turn)
CURRENT_TURN=$(ls -1 "$SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

if [ "$CURRENT_TURN" -eq 0 ]; then
  exit 0
fi

# Collect all available flashback images and render new ones
AVAILABLE=()
COUNT=0

for JSON_FILE in $(ls -1t "$SESSION_DIR"/*.json 2>/dev/null); do
  if [ "$COUNT" -ge "$MAX_IMAGES" ]; then
    break
  fi

  # Get turn number and check if old enough
  ENTRY_DATA=$(node -e "
const fs = require('fs');
const e = JSON.parse(fs.readFileSync('$JSON_FILE', 'utf8'));
console.log([e.turn || 0, e.context_hint || '', e.char_count || 0].join('\t'));
" 2>/dev/null)

  IFS=$'\t' read -r ENTRY_TURN HINT CHAR_COUNT <<< "$ENTRY_DATA"
  TURNS_AGO=$((CURRENT_TURN - ENTRY_TURN))

  if [ "$TURNS_AGO" -lt "$TURNS_THRESHOLD" ]; then
    continue
  fi

  IMG_FILE="${JSON_FILE%.json}.png"

  # Render if not already rendered
  if [ ! -f "$IMG_FILE" ]; then
    HTML_FILE="${JSON_FILE%.json}.html"

    node -e "
const fs = require('fs');
const entry = JSON.parse(fs.readFileSync('$JSON_FILE', 'utf8'));
const content = entry.content || '';
const hint = entry.context_hint || '';

// Escape HTML
const escaped = content
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;');

const html = \`<!DOCTYPE html>
<html>
<head>
<style>
body {
  background: #1e1e1e;
  color: #dcdcdc;
  font-family: Monaco, 'Courier New', monospace;
  font-size: 12px;
  padding: 16px;
  margin: 0;
  line-height: 1.4;
  width: 800px;
}
.header {
  background: #2d2d30;
  color: #9cdcfe;
  padding: 8px 16px;
  margin: -16px -16px 16px -16px;
  font-size: 11px;
  border-bottom: 1px solid #3d3d40;
}
pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
}
</style>
</head>
<body>
<div class='header'>\${hint}</div>
<pre>\${escaped}</pre>
</body>
</html>\`;

fs.writeFileSync('$HTML_FILE', html);
"

    # Convert to PNG using qlmanage
    qlmanage -t -s 800 -o "$SESSION_DIR" "$HTML_FILE" >/dev/null 2>&1

    # qlmanage adds .png to the filename
    if [ -f "${HTML_FILE}.png" ]; then
      mv "${HTML_FILE}.png" "$IMG_FILE"
      rm -f "$HTML_FILE"
    else
      rm -f "$HTML_FILE"
      continue
    fi
  fi

  # Add to available list (whether newly rendered or existing)
  if [ -f "$IMG_FILE" ]; then
    # Use tab as delimiter since hints may contain |
    AVAILABLE+=("${HINT}"$'\t'"${TURNS_AGO}"$'\t'"${IMG_FILE}")
    COUNT=$((COUNT + 1))
  fi
done

# Always show available flashback images in cyan
if [ ${#AVAILABLE[@]} -gt 0 ]; then
  echo -e "${CYAN}[flashback v$LOCAL_VERSION] Visual memory from earlier:${NC}"
  for ITEM in "${AVAILABLE[@]}"; do
    IFS=$'\t' read -r HINT TURNS_AGO IMG_FILE <<< "$ITEM"
    echo -e "${CYAN}  $HINT ($TURNS_AGO turns ago): $IMG_FILE${NC}"
  done
fi

exit 0
