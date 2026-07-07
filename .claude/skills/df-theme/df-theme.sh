#!/usr/bin/env bash
# df-theme.sh -- flip the Dwarf Fortress theme across all three WSL surfaces at once:
#   Alacritty (Windows), Claude Code, and Neovim.
# Usage: df-theme.sh [dark|light|toggle|status]     (default: toggle)
#
# Comment-swap philosophy: no theme definition is ever deleted. Every surface keeps
# BOTH themes defined; this only flips which one is selected --
#   Alacritty : which df_*.toml import line is uncommented   (df_light.toml / df_dark.toml)
#   Claude    : the "theme" value in settings.json           (custom:light-fortress / custom:dark-fortress)
#   Neovim    : the key in nvim's state file                 (df_light / df_dark), reloaded on next launch
set -euo pipefail

ALA="/mnt/c/Users/Pyrus/AppData/Roaming/alacritty/alacritty.toml"
CLAUDE="$HOME/.claude/settings.json"
NVIM_STATE="$HOME/.local/state/nvim/theme"

# Canonical current state = the Claude Code theme value.
current() {
  if   grep -q 'custom:dark-fortress'  "$CLAUDE" 2>/dev/null; then echo dark
  elif grep -q 'custom:light-fortress' "$CLAUDE" 2>/dev/null; then echo light
  else echo unknown; fi
}

cmd="${1:-toggle}"
case "$cmd" in
  dark|light) target="$cmd" ;;
  toggle)     if [ "$(current)" = dark ]; then target=light; else target=dark; fi ;;
  status)
    echo "claude:    $(grep -oE 'custom:(dark|light)-fortress|[a-z-]+-ansi' "$CLAUDE" | head -1)"
    echo "alacritty: $(grep -E '^[[:space:]]*"\./df_(dark|light)\.toml"' "$ALA" | grep -oE 'df_(dark|light)' | head -1) (active import)"
    echo "nvim:      $(cat "$NVIM_STATE" 2>/dev/null || echo 'df_light (default, no state file)')"
    exit 0 ;;
  *) echo "usage: df-theme.sh [dark|light|toggle|status]" >&2; exit 2 ;;
esac

# --- Alacritty: comment-swap the two df import lines. CRLF-preserving (this file is CRLF). ---
tmp="$(mktemp)"
awk -v t="$target" '
{
  if ($0 ~ /df_dark\.toml/ || $0 ~ /df_light\.toml/) {
    match($0, /^[ \t]*/); ind = substr($0, 1, RLENGTH); rest = substr($0, RLENGTH + 1)
    sub(/^#[ \t]*/, "", rest)                                  # normalize: strip any existing comment marker
    active = (($0 ~ /df_dark\.toml/  && t == "dark") ||
              ($0 ~ /df_light\.toml/ && t == "light"))
    if (active) print ind rest; else print ind "# " rest       # trailing \r rides along on rest -> CRLF kept
    next
  }
  print
}' "$ALA" > "$tmp"
cp "$tmp" "$ALA"; rm -f "$tmp"

# --- Claude Code: rewrite the theme value (robust to whatever it was). ---
sed -E -i 's|("theme":[[:space:]]*)"[^"]*"|\1"custom:'"$target"'-fortress"|' "$CLAUDE"

# --- Neovim: write the persisted theme key (read by load_theme() on next launch). ---
mkdir -p "$(dirname "$NVIM_STATE")"
printf '%s\n' "df_$target" > "$NVIM_STATE"

echo "df-theme -> $target"
echo "  alacritty: applied live (live_config_reload is on)"
echo "  claude:    set for next launch -- run /theme and pick ${target^} Fortress to apply in this session"
echo "  nvim:      set for next launch -- in a running nvim, <leader>ut re-picks it live"
