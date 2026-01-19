#!/usr/bin/env bash
# Test runner for mac-maid
set -euo pipefail
IFS=$'\n\t'

# Colors for output
if [[ -t 1 ]]; then
  GREEN="$(printf '\033[32m')"
  RED="$(printf '\033[31m')"
  YELLOW="$(printf '\033[33m')"
  RESET="$(printf '\033[0m')"
  BOLD="$(printf '\033[1m')"
else
  GREEN=""; RED=""; YELLOW=""; RESET=""; BOLD=""
fi

PASSED=0
FAILED=0
SKIPPED=0

# Test result tracking
pass() {
  echo "${GREEN}✓${RESET} $*"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "${RED}✗${RESET} $*"
  FAILED=$((FAILED + 1))
}

skip() {
  echo "${YELLOW}⊘${RESET} $* (skipped)"
  SKIPPED=$((SKIPPED + 1))
}

section() {
  echo
  echo "${BOLD}$*${RESET}"
  echo "────────────────────────────────────────────────────────────"
}

# Run a test file
run_test_file() {
  local test_file="$1"
  if [[ -f "$test_file" ]]; then
    echo
    echo "${BOLD}Running: $(basename "$test_file")${RESET}"
    if bash "$test_file"; then
      pass "Test file completed: $(basename "$test_file")"
    else
      fail "Test file failed: $(basename "$test_file")"
      return 1
    fi
  else
    skip "Test file not found: $test_file"
  fi
}

# Main
main() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "$script_dir/.."

  section "mac-maid Test Suite"
  echo "Running all tests..."

  # Track overall status
  local overall_status=0

  # Run test files in order
  run_test_file "$script_dir/test-safety.sh" || overall_status=1
  run_test_file "$script_dir/test-functions.sh" || overall_status=1
  run_test_file "$script_dir/test-integration.sh" || overall_status=1

  # Summary
  section "Test Summary"
  echo "Passed : ${GREEN}${PASSED}${RESET}"
  echo "Failed : ${RED}${FAILED}${RESET}"
  echo "Skipped: ${YELLOW}${SKIPPED}${RESET}"
  echo

  if [[ "$overall_status" -ne 0 || "$FAILED" -gt 0 ]]; then
    echo "${RED}${BOLD}Tests failed${RESET}"
    exit 1
  else
    echo "${GREEN}${BOLD}All tests passed!${RESET}"
    exit 0
  fi
}

main "$@"
