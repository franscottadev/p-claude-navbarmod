# Claude Navbar Mod

Customized bottom statusline + hooks for Claude Code. Shows model, context window, token counts, rate limits, and active plugins — live, every response.

## Preview

### Statusline

```
Claude Sonnet 4.6 | ctx: 12% (in:3420 out:891) | sess: 48230 tok | 5h: 8% 7d: 2% | ● caveman ● memo
```

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Claude Sonnet 4.6 | ctx: 12% (in:3420 out:891) | sess: 48230 tok | 5h: 8% 7d: 2% | ● caveman ● memo  │
└─────────────────────────────────────────────────────────────────────────────┘
  ▲ model          ▲ context used   ▲ call tokens        ▲ session total   ▲ rate limits   ▲ active skills
```

**Segments:**
| Segment | Example | Description |
|---------|---------|-------------|
| Model | `Claude Sonnet 4.6` | Active model name |
| Context | `ctx: 12%` | Context window used |
| Call tokens | `(in:3420 out:891)` | Input/output tokens this call |
| Session | `sess: 48230 tok` | Total tokens this session |
| Rate limits | `5h: 8% 7d: 2%` | 5-hour and 7-day usage |
| Plugins | `● caveman ● memo` | Active skills/plugins (green dots) |

> Plugin dots: **permanent** flags (skills like caveman) always show. **Temporary** flags (MCP tools like memo, playwright) show for 10s after use.

---

## Install

```sh
git clone https://github.com/your-username/claude-navbar-mod
cd claude-navbar-mod
./install.sh
```

**Then restart Claude Code.**

### Install steps

1. **Scope** — global (`~/.claude/`) or project (`.claude/`)
2. **Preset** — select agent type (currently: `claude-code`)
3. **Skills check** — required skills verified; prompts to install if missing
4. **Backup** — existing files backed up to `~/.claude/backups/navbar-mod-TIMESTAMP/`
5. **Files copied** — `statusline-custom.sh` + `hooks/plugin-tracker.sh`
6. **settings.json patched** — hooks + statusLine merged (existing config preserved)
7. **Done** — restart Claude Code to activate

---

## Requirements

- Claude Code
- `jq` (for JSON parsing in scripts)
- Required skill: **[caveman](https://github.com/anthropics/claude-code)** — ultra-compressed communication mode

---

## Structure

```
claude-navbar-mod/
├── install.sh              # interactive installer
├── statusline-custom.sh    # bottom bar script
├── hooks/
│   └── plugin-tracker.sh  # SessionStart + PostToolUse hooks
└── presets/
    └── claude-code/
        └── preset.json    # preset metadata + required skills
```

---

## Presets

| Preset | Description |
|--------|-------------|
| `claude-code` | Default — model, ctx, tokens, rate limits, plugin dots |

More presets coming.

---

## Uninstall

Restore from backup:

```sh
cp ~/.claude/backups/navbar-mod-TIMESTAMP/settings.json ~/.claude/settings.json
rm ~/.claude/statusline-custom.sh
rm ~/.claude/hooks/plugin-tracker.sh
```
# p-claude-navbarmod
