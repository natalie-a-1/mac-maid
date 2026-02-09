#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT="${HERE}/mac-maid"

if [[ ! -f "$SCRIPT" ]]; then
  echo "✗ mac-maid not found next to install.sh"
  exit 1
fi

chmod +x "$SCRIPT" >/dev/null 2>&1 || true
"$SCRIPT" --install

echo
echo "Installed."
echo "Next:"
echo "  mac-maid --dry-run   # preview wizard safely (no changes)"
echo "  mac-maid             # run wizard for real"

