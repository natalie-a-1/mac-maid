# mac-maid Test Suite

This directory contains the test suite for mac-maid, ensuring code quality and safety guarantees.

## Quick Start

Run all tests:
```bash
./tests/test-runner.sh
```

Run individual test suites:
```bash
./tests/test-safety.sh       # Safety and security tests (17 tests)
./tests/test-functions.sh    # Function unit tests (33 tests)
./tests/test-integration.sh  # Integration tests (13 tests)
```

## Test Organization

### test-runner.sh
Master test runner that executes all test files and reports aggregate results.

### test-safety.sh - Critical Safety Tests
These tests verify the core safety guarantees that mac-maid promises:
- Protected paths are in safety checks (Ollama, configs, SSH, etc.)
- All cleanup toggles default to OFF (opt-in only)
- Dry-run mode is implemented correctly
- Root and HOME directory protection exists
- Script rejects invalid arguments

**These tests must always pass.** They protect users from data loss.

### test-functions.sh - Function Existence & Unit Tests
Verifies that all expected functions exist and work correctly:
- Disk space calculations (`kb_to_gb`, `du_kb`, etc.)
- Time validation (`valid_time_hhmm`)
- All task functions (npm, pnpm, pip, etc.)
- Config functions (read, write, load)
- TUI functions (menus, cursor control)
- LaunchAgent functions

### test-integration.sh - Integration Workflows
Tests end-to-end workflows:
- Command-line interface (help, status, install)
- Config file creation and validation
- Dry-run mode (ensures no files created)
- Invalid config rejection
- Schedule installation (dry-run)

## Writing Tests

### Test Structure
Each test file follows this pattern:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Colors (optional)
GREEN="$(printf '\033[32m')"
RED="$(printf '\033[31m')"
RESET="$(printf '\033[0m')"

PASSED=0
FAILED=0

pass() { echo "${GREEN}✓${RESET} $*"; PASSED=$((PASSED + 1)); }
fail() { echo "${RED}✗${RESET} $*" >&2; FAILED=$((FAILED + 1)); }

# Tests go here
if [[ some_condition ]]; then
  pass "Test description"
else
  fail "Test description"
fi

# Summary
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}All tests passed${RESET}"
  exit 0
else
  echo "${RED}$FAILED tests failed${RESET}"
  exit 1
fi
```

### Important: Counter Increments with `set -e`
Do NOT use `((VAR++))` for counter increments when using `set -euo pipefail`:
```bash
# BAD - will exit when VAR=0
pass() { echo "✓ $*"; ((PASSED++)); }

# GOOD - always succeeds
pass() { echo "✓ $*"; PASSED=$((PASSED + 1)); }
```

The `((expr))` command returns exit code 1 when the expression evaluates to 0, which triggers `set -e` exit.

### Test Isolation
- Integration tests create temporary directories with `mktemp -d`
- Always clean up with `trap 'rm -rf "$TEST_DIR"' EXIT`
- Never modify system state (except in integration tests with cleanup)
- Use `|| true` when testing failure cases to prevent `set -e` exit

## Continuous Integration

Tests run automatically on GitHub Actions for every push to main branches:
- Platform: macOS (target environment)
- Triggers: Push to `main`, `refinement`, `init` branches, and all PRs
- See `.github/workflows/test.yml` for configuration

## Adding New Tests

When adding new functionality to mac-maid:

1. **Safety-critical changes** (new cleanup tasks, path operations):
   - Add tests to `test-safety.sh`
   - Verify protected paths remain protected
   - Ensure opt-in defaults

2. **New functions** (helpers, utilities):
   - Add existence check to `test-functions.sh`
   - Add unit tests for logic

3. **New workflows** (commands, modes):
   - Add integration test to `test-integration.sh`
   - Test both success and failure cases
   - Verify dry-run behavior

## Test Coverage

Current coverage:
- **17 safety tests** - Core protection guarantees
- **33 function tests** - All functions accounted for
- **13 integration tests** - Key workflows validated
- **63 total tests**

All tests must pass before merging changes.
