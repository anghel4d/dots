---
name: df-theme
description: Flip the Dwarf Fortress theme (df-dark <-> df-light) across all three WSL surfaces at once -- Alacritty, Claude Code, and Neovim/nvchad. Use when the user asks to switch, toggle, or set the DF theme, go dark or light, or "show me df-dark / df-light".
---

# df-theme — one-shot DF theme flip

On WSL the Dwarf Fortress look is spread across three configs that must agree, or you get the light-on-light / dark-on-dark mismatch (a light Claude theme uses the terminal's ANSI palette, so if Alacritty is dark and Claude is light, Claude renders unreadable). This flips all three together.

## Run it

```
bash ~/.claude/skills/df-theme/df-theme.sh [dark|light|toggle|status]
```

`toggle` is the default and reads the current state from Claude's theme. Use `dark` / `light` to set explicitly, `status` to print each surface without changing anything.

## What it touches (one selector per surface)

| surface | file | selector |
| --- | --- | --- |
| Alacritty (Windows) | `/mnt/c/Users/Pyrus/AppData/Roaming/alacritty/alacritty.toml` | uncomment `./df_dark.toml` or `./df_light.toml` in the `import` list (CRLF-preserving) |
| Claude Code | `~/.claude/settings.json` | `"theme"` → `custom:dark-fortress` / `custom:light-fortress` |
| Neovim | `~/.local/state/nvim/theme` | writes `df_dark` / `df_light`; `load_theme()` in `init.lua` reads it on startup |

## Live-apply notes

- Alacritty repaints instantly (`live_config_reload`).
- Claude Code reads `theme` at startup — the script sets it, but to apply in the *current* session run `/theme` and pick Dark/Light Fortress (or relaunch).
- Neovim applies on next launch; a running nvim re-picks live with `<leader>ut`.

## Information-preservation guarantee

Nothing is deleted. Every theme definition stays in place — the Alacritty df line is comment-swapped (both lines remain), Claude keeps both `dark-fortress`/`light-fortress` theme files in `~/.claude/themes/`, and nvim keeps both `df_dark`/`df_light` base16 tables in `init.lua §9`. The script only flips which one is pointed at. Safe to run repeatedly; fully reversible by running it the other way.
