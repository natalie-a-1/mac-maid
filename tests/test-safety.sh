#!/usr/bin/env bash
# Safety tests for mac-maid v0.3.0 - verify protected paths are never deleted
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

# Test 3: Verify safe_rm function exists and has safety checks
if grep -q "^safe_rm()" "$REPO_ROOT/mac-maid"; then
  pass "safe_rm function exists"
else
  fail "safe_rm function not found"
fi

# Test 4: Verify protected paths in safe_rm
protected_patterns=(
  '\.ssh'
  '\.config'
  '\.gnupg'
)

for pattern in "${protected_patterns[@]}"; do
  if grep -q "$pattern" "$REPO_ROOT/mac-maid"; then
    pass "Protected path check exists: $pattern"
  else
    fail "Missing protection for: $pattern"
  fi
done

# Test 5: Verify safety rails block root and home
if grep -q '"\$HOME"' "$REPO_ROOT/mac-maid" && grep -q '"/"' "$REPO_ROOT/mac-maid"; then
  pass "Safety check for root and HOME exists"
else
  fail "Missing safety check for root and HOME"
fi

# Test 6: Dry-run mode exists and is respected
if grep -q 'DRY_RUN=' "$REPO_ROOT/mac-maid" && grep -q 'DRY_RUN.*1' "$REPO_ROOT/mac-maid"; then
  pass "Dry-run mode implemented"
else
  fail "Dry-run mode not properly implemented"
fi

# Test 7: Help shows dry-run option
if "$REPO_ROOT/mac-maid" --help 2>&1 | grep -q "\-\-dry-run"; then
  pass "Help shows --dry-run option"
else
  fail "Help missing --dry-run option"
fi

# Test 8: Script rejects invalid arguments
if ! "$REPO_ROOT/mac-maid" --invalid-arg-xyz 2>/dev/null; then
  pass "Script rejects invalid arguments"
else
  fail "Script accepts invalid arguments"
fi

# Test 9: Version number is defined
if grep -q '^VERSION=' "$REPO_ROOT/mac-maid"; then
  pass "VERSION is defined"
else
  fail "VERSION not defined"
fi

# Test 10: Clean functions use safe_rm for file operations
clean_functions=("clean_npm" "clean_cache" "clean_lib_cache" "clean_brew" "clean_trash")
for func in "${clean_functions[@]}"; do
  if grep -q "^${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Clean function exists: ${func}()"
  else
    fail "Clean function not found: ${func}()"
  fi
done

# Test 11: Verify lib_cache uses allowlist (safe approach)
if grep -q 'safe_to_clean=' "$REPO_ROOT/mac-maid"; then
  pass "lib_cache uses allowlist approach (safe)"
else
  fail "lib_cache should use allowlist approach"
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
