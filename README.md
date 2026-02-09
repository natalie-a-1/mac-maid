# mac-maid 🧹

mac-maid is a **safe-by-default** macOS cleanup tool with a clean, keyboard-first wizard.

It cleans **rebuildable** stuff (caches + dev build junk) and can optionally schedule runs using a macOS **LaunchAgent**.

## What it does

- Interactive wizard (↑/↓ to move, Space to toggle, Enter to confirm)
- One-time clean or scheduled auto-clean
- Dry-run mode that **does not** delete files and **does not** write config or schedules

## Safety guarantees

mac-maid will **never** delete:

- `~/.config` (including your terminal/app configs)
- `~/.ssh`
- `~/Library/Application Support`, `~/Library/Keychains`, `~/Library/Mail`, `~/Library/Messages`
- `~/Library/Containers`

`~/.ollama` is cleaned only when you select **Ollama models** in the wizard; `~/.cache/ollama` is never touched. Everything is opt-in. In dry-run, it's all preview. In dry-run, it’s all preview.

## Quick start (run from repo)

```bash
git clone https://github.com/YOURNAME/mac-maid.git
cd mac-maid
chmod +x mac-maid

./mac-maid --dry-run   # walk through wizard safely (no changes)
./mac-maid             # real run (writes config + runs cleanup)

