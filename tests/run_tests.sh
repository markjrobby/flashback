#!/bin/bash
#
# Flashback Test Suite
# Run from project root: ./tests/run_tests.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SCRIPT_DIR/output"
TEST_SESSION="test-session-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Setup
echo -e "${CYAN}Setting up test environment...${NC}"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
export FLASHBACK_STORE_DIR="$OUTPUT_DIR"
export FLASHBACK_MIN_CHARS="100"
export FLASHBACK_TURNS_THRESHOLD="2"

PASSED=0
FAILED=0

pass() {
  echo -e "${GREEN}✓ $1${NC}"
  PASSED=$((PASSED + 1))
}

fail() {
  echo -e "${RED}✗ $1${NC}"
  FAILED=$((FAILED + 1))
}

# Test 1: Capture script creates JSON file
echo ""
echo "Test 1: Capture script creates JSON file"
python3 -c "
import json
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Read',
    'tool_use_id': 'test_001',
    'tool_input': {'file_path': 'src/example.py'},
    'tool_response': 'x' * 500
}))
" | bash "$PROJECT_DIR/scripts/capture.sh"

if [ -f "$OUTPUT_DIR/$TEST_SESSION"/*.json ]; then
  pass "Capture creates JSON file"
else
  fail "Capture did not create JSON file"
fi

# Test 2: Capture ignores small content
echo ""
echo "Test 2: Capture ignores small content (below threshold)"
BEFORE_COUNT=$(ls -1 "$OUTPUT_DIR/$TEST_SESSION"/*.json 2>/dev/null | wc -l | tr -d ' ')
python3 -c "
import json
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Read',
    'tool_use_id': 'test_small',
    'tool_input': {'file_path': 'small.txt'},
    'tool_response': 'tiny'
}))
" | bash "$PROJECT_DIR/scripts/capture.sh"
AFTER_COUNT=$(ls -1 "$OUTPUT_DIR/$TEST_SESSION"/*.json 2>/dev/null | wc -l | tr -d ' ')

if [ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ]; then
  pass "Capture ignores small content"
else
  fail "Capture should have ignored small content"
fi

# Test 3: Add more entries to trigger inject
echo ""
echo "Test 3: Adding entries for inject test"
for i in 2 3 4; do
  sleep 1
  python3 -c "
import json
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Bash',
    'tool_use_id': 'test_00$i',
    'tool_input': {'command': 'echo test $i'},
    'tool_response': 'Output from command $i: ' + 'y' * 200
}))
" | bash "$PROJECT_DIR/scripts/capture.sh"
done

ENTRY_COUNT=$(ls -1 "$OUTPUT_DIR/$TEST_SESSION"/*.json 2>/dev/null | wc -l | tr -d ' ')
if [ "$ENTRY_COUNT" -eq 4 ]; then
  pass "Created 4 entries for inject test"
else
  fail "Expected 4 entries, got $ENTRY_COUNT"
fi

# Test 4: Inject renders PNG and shows output
echo ""
echo "Test 4: Inject renders PNG and shows notification"
INJECT_OUTPUT=$(echo "{\"session_id\":\"$TEST_SESSION\"}" | bash "$PROJECT_DIR/scripts/inject.sh" 2>&1)

if echo "$INJECT_OUTPUT" | grep -q "\[flashback"; then
  pass "Inject shows notification"
else
  fail "Inject did not show notification"
fi

PNG_COUNT=$(ls -1 "$OUTPUT_DIR/$TEST_SESSION"/*.png 2>/dev/null | wc -l | tr -d ' ')
if [ "$PNG_COUNT" -gt 0 ]; then
  pass "Inject created PNG file(s): $PNG_COUNT"
else
  fail "Inject did not create PNG files"
fi

# Test 5: Inject shows existing PNGs on subsequent runs
echo ""
echo "Test 5: Inject shows existing PNGs on re-run"
INJECT_OUTPUT2=$(echo "{\"session_id\":\"$TEST_SESSION\"}" | bash "$PROJECT_DIR/scripts/inject.sh" 2>&1)

if echo "$INJECT_OUTPUT2" | grep -q "\[flashback"; then
  pass "Inject shows existing flashbacks on re-run"
else
  fail "Inject did not show existing flashbacks"
fi

# Test 6: JSON content is valid
echo ""
echo "Test 6: JSON files have valid structure"
FIRST_JSON=$(ls -1 "$OUTPUT_DIR/$TEST_SESSION"/*.json 2>/dev/null | head -1)
VALID=$(node -e "
const fs = require('fs');
const e = JSON.parse(fs.readFileSync('$FIRST_JSON'));
if (e.tool_name && e.content && e.timestamp && e.context_hint) {
  console.log('valid');
}
" 2>/dev/null)

if [ "$VALID" = "valid" ]; then
  pass "JSON structure is valid"
else
  fail "JSON structure is invalid"
fi

# Summary
echo ""
echo "=============================="
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "=============================="

# Cleanup
rm -rf "$OUTPUT_DIR/$TEST_SESSION"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
