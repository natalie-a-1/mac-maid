#!/usr/bin/env bash
# Unit tests for mac-maid v0.3.0 helper functions
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

echo "Testing helper functions..."

# Test 1: human() function for human-readable sizes
if grep -q "^human()" "$REPO_ROOT/mac-maid"; then
  pass "human() function exists for size formatting"
else
  fail "human() function not found"
fi

# Test 2: size_kb() function for fast size check
if grep -q "^size_kb()" "$REPO_ROOT/mac-maid"; then
  pass "size_kb() function exists"
else
  fail "size_kb() function not found"
fi

# Test 3: have() function for command checking
if grep -q "^have()" "$REPO_ROOT/mac-maid"; then
  pass "have() function exists for command checking"
else
  fail "have() function not found"
fi

# Test 4: Output helper functions exist
output_functions=("ok" "info" "warn" "err" "dim")
for func in "${output_functions[@]}"; do
  if grep -q "^${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Output function exists: ${func}()"
  else
    fail "Output function not found: ${func}()"
  fi
done

# Test 5: Target helper functions
if grep -q "^get_key()" "$REPO_ROOT/mac-maid"; then
  pass "get_key() function exists"
else
  fail "get_key() function not found"
fi

if grep -q "^get_name()" "$REPO_ROOT/mac-maid"; then
  pass "get_name() function exists"
else
  fail "get_name() function not found"
fi

# Test 6: Cleanup functions exist
clean_functions=(
  "clean_npm"
  "clean_pnpm"
  "clean_pip"
  "clean_hf"
  "clean_ollama"
  "clean_cache"
  "clean_lib_cache"
  "clean_brew"
  "clean_xcode"
  "clean_ios_sim"
  "clean_trash"
  "clean_node_modules"
  "clean_venvs"
  "clean_docker"
  "clean_git"
)

for func in "${clean_functions[@]}"; do
  if grep -q "^${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Cleanup function exists: ${func}()"
  else
    fail "Cleanup function not found: ${func}()"
  fi
done

# Test 7: Core functions
if grep -q "^tui_menu()" "$REPO_ROOT/mac-maid"; then
  pass "tui_menu() function exists"
else
  fail "tui_menu() function not found"
fi

if grep -q "^estimate_sizes()" "$REPO_ROOT/mac-maid"; then
  pass "estimate_sizes() function exists"
else
  fail "estimate_sizes() function not found"
fi

if grep -q "^run_cleanup()" "$REPO_ROOT/mac-maid"; then
  pass "run_cleanup() function exists"
else
  fail "run_cleanup() function not found"
fi

if grep -q "^safe_rm()" "$REPO_ROOT/mac-maid"; then
  pass "safe_rm() function exists"
else
  fail "safe_rm() function not found"
fi

# Test 8: TARGETS array exists with key:value format
if grep -q 'TARGETS=(' "$REPO_ROOT/mac-maid" && grep -q '"npm:NPM cache"' "$REPO_ROOT/mac-maid"; then
  pass "TARGETS array with key:value format exists"
else
  fail "TARGETS array not properly defined"
fi

# Test 9: SELECTED and SIZES arrays exist
if grep -q 'SELECTED=()' "$REPO_ROOT/mac-maid" && grep -q 'SIZES=()' "$REPO_ROOT/mac-maid"; then
  pass "SELECTED and SIZES arrays exist"
else
  fail "SELECTED or SIZES arrays not found"
fi

# Test 10: Verify usage/help function
if grep -q "^usage()" "$REPO_ROOT/mac-maid"; then
  pass "usage() function exists"
else
  fail "usage() function not found"
fi

# Test 11: main() function exists
if grep -q "^main()" "$REPO_ROOT/mac-maid"; then
  pass "main() function exists"
else
  fail "main() function not found"
fi

# Summary
echo
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}Function tests: $PASSED passed${RESET}"
  exit 0
else
  echo "${RED}Function tests: $FAILED failed, $PASSED passed${RESET}"
  exit 1
fi
