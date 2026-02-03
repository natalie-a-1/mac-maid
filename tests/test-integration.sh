#!/usr/bin/env bash
# Integration tests for mac-maid v0.3.0
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

echo "Testing integration workflows..."

# Test 1: Help command succeeds
if "$REPO_ROOT/mac-maid" --help >/dev/null 2>&1; then
  pass "Help command succeeds"
else
  fail "Help command failed"
fi

# Test 2: Status command succeeds
if "$REPO_ROOT/mac-maid" --status >/dev/null 2>&1; then
  pass "Status command succeeds"
else
  fail "Status command failed"
fi

# Test 3: Dry-run mode shows dry-run message
output=$("$REPO_ROOT/mac-maid" --dry-run --all --yes 2>&1 || true)
if echo "$output" | grep -qi "dry.run"; then
  pass "Dry-run mode shows dry-run message"
else
  fail "Dry-run mode doesn't show dry-run message"
fi

# Test 4: Script is executable
if [[ -x "$REPO_ROOT/mac-maid" ]]; then
  pass "mac-maid script is executable"
else
  fail "mac-maid script is not executable"
fi

# Test 5: Version matches expected format
version=$(grep '^VERSION=' "$REPO_ROOT/mac-maid" | cut -d'"' -f2)
if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  pass "Version format is valid: $version"
else
  fail "Version format invalid: $version"
fi

# Test 6: install.sh exists and is executable
if [[ -x "$REPO_ROOT/install.sh" ]]; then
  pass "install.sh exists and is executable"
else
  fail "install.sh missing or not executable"
fi

# Test 7: uninstall.sh exists and is executable
if [[ -x "$REPO_ROOT/uninstall.sh" ]]; then
  pass "uninstall.sh exists and is executable"
else
  fail "uninstall.sh missing or not executable"
fi

# Test 8: README.md exists
if [[ -f "$REPO_ROOT/README.md" ]]; then
  pass "README.md exists"
else
  fail "README.md missing"
fi

# Test 9: All CLI options are documented in help
help_output=$("$REPO_ROOT/mac-maid" --help 2>&1)
for opt in "--dry-run" "--all" "--yes" "--status"; do
  if echo "$help_output" | grep -q -- "$opt"; then
    pass "Help documents option: $opt"
  else
    fail "Help missing option: $opt"
  fi
done

# Test 10: Colors are disabled when not a TTY
output=$(echo "" | "$REPO_ROOT/mac-maid" --help 2>&1)
# Check that ANSI escape codes are not present when piped
if ! echo "$output" | grep -q $'\033'; then
  pass "Colors disabled when not a TTY"
else
  fail "Colors still present when not a TTY"
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
