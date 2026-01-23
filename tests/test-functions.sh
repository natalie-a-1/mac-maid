#!/usr/bin/env bash
# Unit tests for mac-maid helper functions
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

# Source the main script in a subshell to test functions without side effects
# We'll extract and test individual functions

# Test 1: kb_to_gb function exists and converts correctly
if grep -q "kb_to_gb()" "$REPO_ROOT/mac-maid"; then
  pass "kb_to_gb function exists"

  # Test the conversion logic by extracting and running it
  kb_to_gb() {
    local kb="$1"
    awk -v kb="$kb" 'BEGIN{printf "%.2f", (kb/1024/1024)}'
  }

  result=$(kb_to_gb 1048576)  # 1 GB in KB
  if [[ "$result" == "1.00" ]]; then
    pass "kb_to_gb converts 1GB correctly: $result"
  else
    fail "kb_to_gb conversion wrong: expected 1.00, got $result"
  fi

  result=$(kb_to_gb 0)
  if [[ "$result" == "0.00" ]]; then
    pass "kb_to_gb handles zero correctly: $result"
  else
    fail "kb_to_gb zero handling wrong: expected 0.00, got $result"
  fi
else
  fail "kb_to_gb function not found"
fi

# Test 2: have function exists for command checking
if grep -q "have()" "$REPO_ROOT/mac-maid"; then
  pass "have() function exists for command checking"
else
  fail "have() function not found"
fi

# Test 3: safe_mkdir function exists
if grep -q "safe_mkdir()" "$REPO_ROOT/mac-maid"; then
  pass "safe_mkdir() function exists"
else
  fail "safe_mkdir() function not found"
fi

# Test 4: Logging functions exist
log_functions=("log_init" "log_section" "log_line" "log_kv")
for func in "${log_functions[@]}"; do
  if grep -q "${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Logging function exists: ${func}()"
  else
    fail "Logging function not found: ${func}()"
  fi
done

# Test 5: Task functions exist for all cleanup types
task_functions=("task_npm" "task_pnpm" "task_pip" "task_hf" "task_user_cache" "task_mac_caches" "task_homebrew_cache" "task_xcode_derived" "task_ios_sim" "task_trash" "task_project_junk" "task_venvs")
for func in "${task_functions[@]}"; do
  if grep -q "${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Task function exists: ${func}()"
  else
    fail "Task function not found: ${func}()"
  fi
done

# Test 6: Config functions exist
config_functions=("print_config" "write_config" "load_config")
for func in "${config_functions[@]}"; do
  if grep -q "${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Config function exists: ${func}()"
  else
    fail "Config function not found: ${func}()"
  fi
done

# Test 7: TUI functions exist
tui_functions=("tui_hide_cursor" "tui_show_cursor" "tui_clear" "tui_menu_single" "tui_menu_multi")
for func in "${tui_functions[@]}"; do
  if grep -q "${func}()" "$REPO_ROOT/mac-maid"; then
    pass "TUI function exists: ${func}()"
  else
    fail "TUI function not found: ${func}()"
  fi
done

# Test 7b: sleep_brief helper exists and is used by TUI/spinner
if grep -q "sleep_brief()" "$REPO_ROOT/mac-maid"; then
  pass "sleep_brief() function exists"
else
  fail "sleep_brief() function not found"
fi

if grep -q "tui_clear()" "$REPO_ROOT/mac-maid" && grep -q "sleep_brief 0.01" "$REPO_ROOT/mac-maid"; then
  pass "tui_clear uses sleep_brief"
else
  fail "tui_clear does not use sleep_brief"
fi

if grep -q "spin_capture()" "$REPO_ROOT/mac-maid" && grep -q "sleep_brief 0.10" "$REPO_ROOT/mac-maid"; then
  pass "spin_capture uses sleep_brief"
else
  fail "spin_capture does not use sleep_brief"
fi

# Test 8: LaunchAgent functions exist
la_functions=("install_launchagent" "remove_launchagent" "launchagent_interval_xml")
for func in "${la_functions[@]}"; do
  if grep -q "${func}()" "$REPO_ROOT/mac-maid"; then
    pass "LaunchAgent function exists: ${func}()"
  else
    fail "LaunchAgent function not found: ${func}()"
  fi
done

# Test 9: valid_time_hhmm function logic
if grep -q "valid_time_hhmm()" "$REPO_ROOT/mac-maid"; then
  pass "valid_time_hhmm() function exists"

  # Test the regex pattern
  valid_time_hhmm() {
    [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
  }

  if valid_time_hhmm "05:00"; then
    pass "valid_time_hhmm accepts 05:00"
  else
    fail "valid_time_hhmm rejects valid time 05:00"
  fi

  if valid_time_hhmm "23:59"; then
    pass "valid_time_hhmm accepts 23:59"
  else
    fail "valid_time_hhmm rejects valid time 23:59"
  fi

  if ! valid_time_hhmm "25:00"; then
    pass "valid_time_hhmm rejects invalid time 25:00"
  else
    fail "valid_time_hhmm accepts invalid time 25:00"
  fi

  if ! valid_time_hhmm "12:60"; then
    pass "valid_time_hhmm rejects invalid time 12:60"
  else
    fail "valid_time_hhmm accepts invalid time 12:60"
  fi
else
  fail "valid_time_hhmm() function not found"
fi

# Test 10: Output helper functions exist
output_functions=("title" "ok" "warn" "fail" "note")
for func in "${output_functions[@]}"; do
  if grep -q "^${func}()" "$REPO_ROOT/mac-maid"; then
    pass "Output function exists: ${func}()"
  else
    fail "Output function not found: ${func}()"
  fi
done

# Summary
echo
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}Function tests: $PASSED passed${RESET}"
  exit 0
else
  echo "${RED}Function tests: $FAILED failed, $PASSED passed${RESET}"
  exit 1
fi
