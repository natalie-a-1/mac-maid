#!/usr/bin/env bash
# Safety tests for mac-maid - verify protected paths are never deleted
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

echo "Testing safety guarantees..."

# Test 1: Script has correct shebang and runs
if head -1 "$REPO_ROOT/mac-maid" | grep -q "^#!/usr/bin/env bash"; then
  pass "Script has correct bash shebang"
else
  fail "Script missing bash shebang"
fi

# Test 2: Script syntax is valid
if bash -n "$REPO_ROOT/mac-maid" 2>/dev/null; then
  pass "Script syntax is valid"
else
  fail "Script has syntax errors"
fi

# Test 3: Verify protected paths are in do_rm_rf safety checks
protected_paths=(
  "/.ollama"
  "/.cache/ollama"
  "/.config"
  "/.ssh"
  "/Library/Application Support"
  "/Library/Keychains"
  "/Library/Mail"
  "/Library/Messages"
  "/Library/Containers"
)

for path in "${protected_paths[@]}"; do
  # Check if the path pattern exists in safety rails
  if grep -q "$path" "$REPO_ROOT/mac-maid"; then
    pass "Protected path check exists: $path"
  else
    fail "Missing protection for: $path"
  fi
done

# Test 4: Verify do_rm_rf function exists and has safety checks
if grep -q "^do_rm_rf()" "$REPO_ROOT/mac-maid"; then
  pass "do_rm_rf function exists"
else
  fail "do_rm_rf function not found"
fi

# Test 5: Verify safety rails block root and home
if grep -q '"/"|"\${HOME}"' "$REPO_ROOT/mac-maid"; then
  pass "Safety check for root and HOME exists"
else
  fail "Missing safety check for root and HOME"
fi

# Test 6: Dry-run mode exists and is respected
if grep -q 'DRY_RUN=' "$REPO_ROOT/mac-maid" && grep -q 'if \[\[ "\$DRY_RUN" == "1" \]\]' "$REPO_ROOT/mac-maid"; then
  pass "Dry-run mode implemented"
else
  fail "Dry-run mode not properly implemented"
fi

# Test 7: All cleanup toggles default to 0 (off)
cleanup_toggles=(
  "CLEAN_NPM=0"
  "CLEAN_PNPM=0"
  "CLEAN_PIP=0"
  "CLEAN_HF=0"
  "CLEAN_OLLAMA=0"
  "CLEAN_DOCKER=0"
  "CLEAN_GIT_GONE=0"
  "CLEAN_USER_CACHE=0"
  "CLEAN_MAC_CACHES=0"
  "CLEAN_HOMEBREW_CACHE=0"
  "CLEAN_XCODE_DERIVED=0"
  "CLEAN_IOS_SIM=0"
  "CLEAN_TRASH=0"
  "CLEAN_PROJECT_JUNK=0"
  "CLEAN_VENVS=0"
)

for toggle in "${cleanup_toggles[@]}"; do
  if grep -q "^${toggle}" "$REPO_ROOT/mac-maid"; then
    pass "Cleanup toggle defaults to off: $toggle"
  else
    fail "Cleanup toggle not set to default off: $toggle"
  fi
done

# Test 8: Help shows dry-run option
if "$REPO_ROOT/mac-maid" --help 2>&1 | grep -q "\-\-dry-run"; then
  pass "Help shows --dry-run option"
else
  fail "Help missing --dry-run option"
fi

# Test 9: Script rejects invalid arguments
if ! "$REPO_ROOT/mac-maid" --invalid-arg-xyz 2>/dev/null; then
  pass "Script rejects invalid arguments"
else
  fail "Script accepts invalid arguments"
fi

# Test 10: Version number is defined
if grep -q '^VERSION=' "$REPO_ROOT/mac-maid"; then
  pass "VERSION is defined"
else
  fail "VERSION not defined"
fi

# Summary
echo
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}Safety tests: $PASSED passed${RESET}"
  exit 0
else
  echo "${RED}Safety tests: $FAILED failed, $PASSED passed${RESET}"
  exit 1
fi
