#!/usr/bin/env bash
# Integration tests for mac-maid - test actual workflows
set -euo pipefail
IFS=$'\n\t'

# Colors
if [[ -t 1 ]]; then
  GREEN="$(printf '\033[32m')"; RED="$(printf '\033[31m')"; RESET="$(printf '\033[0m')"
else
  GREEN=""; RED=""; RESET=""
fi

PASSED=0
FAILED=0

pass() { echo "${GREEN}✓${RESET} $*"; PASSED=$((PASSED + 1)); }
fail() { echo "${RED}✗${RESET} $*" >&2; FAILED=$((FAILED + 1)); }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create temp directory for test artifacts
TEST_DIR="$(mktemp -d -t mac-maid-test.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "Testing integration workflows..."
echo "Test directory: $TEST_DIR"
echo

# Test 1: Help displays correctly
if "$REPO_ROOT/mac-maid" --help >/dev/null 2>&1; then
  pass "Help command succeeds"
else
  fail "Help command fails"
fi

# Test 2: Status command works
if "$REPO_ROOT/mac-maid" --status >/dev/null 2>&1; then
  pass "Status command succeeds"
else
  fail "Status command fails"
fi

# Test 3: Install in dry-run mode
if "$REPO_ROOT/mac-maid" --install --dry-run >/dev/null 2>&1; then
  pass "Install dry-run succeeds"
else
  fail "Install dry-run fails"
fi

# Test 4: Create and validate a test config
TEST_CONFIG="$TEST_DIR/test-config"
cat > "$TEST_CONFIG" <<EOF
# Test config
LOG_DIR="$TEST_DIR/logs"
NOTIFY_ON_COMPLETE=0
SHOW_LOGIN_SUMMARY=0

CLEAN_NPM=1
CLEAN_PNPM=0
CLEAN_PIP=0
CLEAN_HF=0
CLEAN_USER_CACHE=0
CLEAN_MAC_CACHES=0
CLEAN_HOMEBREW_CACHE=0
CLEAN_XCODE_DERIVED=0
CLEAN_IOS_SIM=0
CLEAN_TRASH=0
CLEAN_PROJECT_JUNK=0
CLEAN_VENVS=0

PROJECT_ROOTS="$HOME/Desktop"

SCHEDULE_ENABLED=0
SCHEDULE_MODE="daily"
SCHEDULE_TIME="05:00"
SCHEDULE_WEEKDAY="2"
SCHEDULE_MONTHDAY="1"

ALLOW_WAKE=0
WAKE_TIME="04:58:00"
SLEEP_TIME="05:20:00"
EOF

if bash -n "$TEST_CONFIG" 2>/dev/null; then
  pass "Test config has valid bash syntax"
else
  fail "Test config has syntax errors"
fi

# Test 5: Run with test config in dry-run mode
if "$REPO_ROOT/mac-maid" --run --config "$TEST_CONFIG" --dry-run 2>&1 | grep -q "Dry-run"; then
  pass "Dry-run with config succeeds"
else
  fail "Dry-run with config fails"
fi

# Test 6: Verify dry-run creates no files
BEFORE_COUNT=$(find "$TEST_DIR" -type f | wc -l)
"$REPO_ROOT/mac-maid" --run --config "$TEST_CONFIG" --dry-run >/dev/null 2>&1 || true
AFTER_COUNT=$(find "$TEST_DIR" -type f | wc -l)

if [[ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ]]; then
  pass "Dry-run creates no additional files"
else
  fail "Dry-run created files (before: $BEFORE_COUNT, after: $AFTER_COUNT)"
fi

# Test 7: Schedule dry-run doesn't create LaunchAgent
LA_PLIST="$HOME/Library/LaunchAgents/com.macmaid.clean.plist"
LA_EXISTS_BEFORE=0
[[ -f "$LA_PLIST" ]] && LA_EXISTS_BEFORE=1

"$REPO_ROOT/mac-maid" --schedule --config "$TEST_CONFIG" --dry-run >/dev/null 2>&1 || true

LA_EXISTS_AFTER=0
[[ -f "$LA_PLIST" ]] && LA_EXISTS_AFTER=1

if [[ "$LA_EXISTS_BEFORE" -eq "$LA_EXISTS_AFTER" ]]; then
  pass "Schedule dry-run doesn't modify LaunchAgent"
else
  fail "Schedule dry-run modified LaunchAgent"
fi

# Test 8: Verify install.sh exists and is executable
if [[ -x "$REPO_ROOT/install.sh" ]]; then
  pass "install.sh exists and is executable"
else
  fail "install.sh missing or not executable"
fi

# Test 9: Verify uninstall.sh exists and is executable
if [[ -x "$REPO_ROOT/uninstall.sh" ]]; then
  pass "uninstall.sh exists and is executable"
else
  fail "uninstall.sh missing or not executable"
fi

# Test 10: README exists
if [[ -f "$REPO_ROOT/README.md" ]]; then
  pass "README.md exists"
else
  fail "README.md missing"
fi

# Test 11: Test config with all cleanup options enabled
TEST_CONFIG_ALL="$TEST_DIR/test-config-all"
cat > "$TEST_CONFIG_ALL" <<EOF
LOG_DIR="$TEST_DIR/logs"
NOTIFY_ON_COMPLETE=0
SHOW_LOGIN_SUMMARY=0

CLEAN_NPM=1
CLEAN_PNPM=1
CLEAN_PIP=1
CLEAN_HF=1
CLEAN_USER_CACHE=1
CLEAN_MAC_CACHES=1
CLEAN_HOMEBREW_CACHE=1
CLEAN_XCODE_DERIVED=1
CLEAN_IOS_SIM=1
CLEAN_TRASH=1
CLEAN_PROJECT_JUNK=1
CLEAN_VENVS=1

PROJECT_ROOTS="$TEST_DIR/test-projects"

SCHEDULE_ENABLED=0
SCHEDULE_MODE="daily"
SCHEDULE_TIME="05:00"
SCHEDULE_WEEKDAY="2"
SCHEDULE_MONTHDAY="1"

ALLOW_WAKE=0
WAKE_TIME="04:58:00"
SLEEP_TIME="05:20:00"
EOF

# Create test project structure
mkdir -p "$TEST_DIR/test-projects/project1/node_modules"
mkdir -p "$TEST_DIR/test-projects/project2/.venv"
touch "$TEST_DIR/test-projects/project1/node_modules/test.txt"
touch "$TEST_DIR/test-projects/project2/.venv/test.txt"

if "$REPO_ROOT/mac-maid" --run --config "$TEST_CONFIG_ALL" --dry-run 2>&1 | grep -q "Dry-run"; then
  pass "Dry-run with all options shows dry-run message"
else
  fail "Dry-run with all options doesn't show dry-run message"
fi

# Verify dry-run didn't actually delete the test files
if [[ -f "$TEST_DIR/test-projects/project1/node_modules/test.txt" ]] && [[ -f "$TEST_DIR/test-projects/project2/.venv/test.txt" ]]; then
  pass "Dry-run preserved test files"
else
  fail "Dry-run deleted test files"
fi

# Test 12: Verify script is executable
if [[ -x "$REPO_ROOT/mac-maid" ]]; then
  pass "mac-maid script is executable"
else
  fail "mac-maid script not executable"
fi

# Test 13: Test that invalid config fails appropriately
INVALID_CONFIG="$TEST_DIR/invalid-config"
echo "INVALID SYNTAX HERE ===" > "$INVALID_CONFIG"

OUTPUT=$("$REPO_ROOT/mac-maid" --run --config "$INVALID_CONFIG" 2>&1) || true
if echo "$OUTPUT" | grep -qi "error\|fail\|command not found\|not found"; then
  pass "Invalid config is rejected"
else
  fail "Invalid config not properly rejected"
fi

# Summary
echo
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}Integration tests: $PASSED passed${RESET}"
  exit 0
else
  echo "${RED}Integration tests: $FAILED failed, $PASSED passed${RESET}"
  exit 1
fi
