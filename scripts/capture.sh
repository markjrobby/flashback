#!/bin/bash
#
# Flashback - Capture Hook
# Silently stores large tool outputs for later rendering
#

# Configuration
MIN_CHARS="${FLASHBACK_MIN_CHARS:-1000}"
STORE_DIR="${FLASHBACK_STORE_DIR:-$HOME/.flashback}"

# Read JSON from stdin to temp file (avoids shell escaping issues)
TEMP_INPUT=$(mktemp)
cat > "$TEMP_INPUT"

# Parse JSON using Node.js (available since Claude Code requires it)
PARSED=$(node -e "
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('$TEMP_INPUT', 'utf8'));
const sessionId = input.session_id || 'unknown';
const toolName = input.tool_name || '';
const toolUseId = input.tool_use_id || '';

// Extract content based on tool type
let content = '';
const resp = input.tool_response;
if (typeof resp === 'string') {
  content = resp;
} else if (resp && typeof resp === 'object') {
  content = resp.content || resp.stdout || resp.output || '';
  if (resp.stderr) content += resp.stderr;
  if (resp.results) {
    if (Array.isArray(resp.results)) content = resp.results.join('\n');
    else content = String(resp.results);
  }
}

// Context hint
let hint = toolName;
const inp = input.tool_input || {};
if (toolName === 'Read' && inp.file_path) hint = inp.file_path;
else if (toolName === 'Bash' && inp.command) hint = inp.command.substring(0, 50);
else if (toolName === 'Grep' && inp.pattern) hint = 'grep: ' + inp.pattern;

// Output tab-separated
console.log([sessionId, toolName, toolUseId, content.length, hint].join('\t'));
" 2>/dev/null)

# Parse the output
IFS=$'\t' read -r SESSION_ID TOOL_NAME TOOL_USE_ID CHAR_COUNT CONTEXT_HINT <<< "$PARSED"

# Check if content is large enough
if [ -z "$CHAR_COUNT" ] || [ "$CHAR_COUNT" -lt "$MIN_CHARS" ]; then
  rm -f "$TEMP_INPUT"
  exit 0
fi

# Create session directory
SESSION_DIR="$STORE_DIR/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Count existing files (approximate turn count)
TURN=$(ls -1 "$SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

# Save metadata
TIMESTAMP=$(date +%s)
FILENAME="${TIMESTAMP}_${TOOL_USE_ID:0:8}"

# Write the full entry using Node.js for proper JSON handling
node -e "
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('$TEMP_INPUT', 'utf8'));
const resp = input.tool_response;

let content = '';
if (typeof resp === 'string') {
  content = resp;
} else if (resp && typeof resp === 'object') {
  content = resp.content || resp.stdout || resp.output || '';
  if (resp.stderr) content += resp.stderr;
  if (resp.results) {
    if (Array.isArray(resp.results)) content = resp.results.join('\n');
    else content = String(resp.results);
  }
}

let hint = '$TOOL_NAME';
const inp = input.tool_input || {};
if ('$TOOL_NAME' === 'Read' && inp.file_path) hint = inp.file_path;
else if ('$TOOL_NAME' === 'Bash' && inp.command) hint = inp.command.substring(0, 50);
else if ('$TOOL_NAME' === 'Grep' && inp.pattern) hint = 'grep: ' + inp.pattern;

const entry = {
  tool_name: '$TOOL_NAME',
  tool_input: input.tool_input,
  content: content,
  timestamp: $TIMESTAMP,
  turn: $TURN,
  char_count: content.length,
  tool_use_id: '$TOOL_USE_ID',
  context_hint: hint
};

fs.writeFileSync('$SESSION_DIR/$FILENAME.json', JSON.stringify(entry, null, 2));
"

# Cleanup
rm -f "$TEMP_INPUT"

exit 0
