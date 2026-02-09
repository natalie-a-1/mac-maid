#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT="${HERE}/mac-maid"

PURGE=0
YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge) PURGE=1; shift ;;
    --yes) YES=1; shift ;;
    -h|--help)
      cat <<HELP
Usage:
  ./uninstall.sh           # remove schedules + uninstall mac-maid from PATH
  ./uninstall.sh --purge   # also delete config + logs
  ./uninstall.sh --yes     # non-interactive defaults
HELP
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

run_cmd() {
  if command -v mac-maid >/dev/null 2>&1; then
    if [[ "$PURGE" == "1" ]]; then
      mac-maid --uninstall --purge ${YES:+--yes}
    else
      mac-maid --uninstall ${YES:+--yes}
    fi
  else
    chmod +x "$SCRIPT" || true
    if [[ "$PURGE" == "1" ]]; then
      "$SCRIPT" --uninstall --purge ${YES:+--yes}
    else
      "$SCRIPT" --uninstall ${YES:+--yes}
    fi
  fi
}

run_cmd

