#!/bin/sh
set -e

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

say()  { printf "${BOLD}%s${RESET}\n" "$1"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "${YELLOW}⚠${RESET}  %s\n" "$1"; }
err()  { printf "${RED}✗${RESET} %s\n" "$1"; }
ask()  { printf "${BOLD}%s${RESET} " "$1"; }

echo ""
say "Claude Navbar Mod — Uninstaller"
echo "────────────────────────────────"
echo ""

# ── 1. Scope ──────────────────────────────────────────────────────────────────
echo "Uninstall from:"
echo "  1) Global  (~/.claude/)      — all projects"
echo "  2) Project (.claude/)        — current project only"
echo ""
ask "Choose [1/2] (default: 1):"
read scope_choice
case "${scope_choice:-1}" in
  2) CLAUDE_DIR="$(pwd)/.claude" ;;
  *) CLAUDE_DIR="$HOME/.claude" ;;
esac
ok "Scope: $CLAUDE_DIR"

# ── 2. Find latest backup ─────────────────────────────────────────────────────
echo ""
say "Looking for backups..."

BACKUP_PARENT="$CLAUDE_DIR/backups"
LATEST_BACKUP=""
if [ -d "$BACKUP_PARENT" ]; then
  LATEST_BACKUP=$(ls -dt "$BACKUP_PARENT"/navbar-mod-* 2>/dev/null | head -1)
fi

if [ -n "$LATEST_BACKUP" ]; then
  ok "Found backup: $LATEST_BACKUP"
  echo ""
  echo "Restore options:"
  echo "  1) Restore from latest backup  ($LATEST_BACKUP)"
  echo "  2) Remove files only (no restore)"
  echo ""
  ask "Choose [1/2] (default: 1):"
  read restore_choice
else
  warn "No backup found — files will be removed only"
  restore_choice=2
fi

# ── 3. Confirm ────────────────────────────────────────────────────────────────
echo ""
warn "This will remove statusline-custom.sh, hooks/plugin-tracker.sh, and patch settings.json."
ask "Continue? [y/N]:"
read confirm
case "$confirm" in
  y|Y) ;;
  *) err "Aborted."; exit 1 ;;
esac

# ── 4. Remove files ───────────────────────────────────────────────────────────
echo ""
say "Removing files..."

remove_if_exists() {
  if [ -f "$1" ]; then
    rm "$1"
    ok "Removed $1"
  else
    warn "Not found (skipping): $1"
  fi
}
remove_if_exists "$CLAUDE_DIR/statusline-custom.sh"
remove_if_exists "$CLAUDE_DIR/hooks/plugin-tracker.sh"

# ── 5. Patch settings.json ────────────────────────────────────────────────────
echo ""
say "Patching settings.json..."

SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS" ]; then
  warn "settings.json not found — skipping"
else
  case "${restore_choice:-1}" in
    1)
      if [ -f "$LATEST_BACKUP/settings.json" ]; then
        cp "$LATEST_BACKUP/settings.json" "$SETTINGS"
        ok "settings.json restored from backup"
      else
        warn "No settings.json in backup — removing navbar keys manually"
        restore_choice=2
      fi
      ;;
  esac

  if [ "${restore_choice}" = "2" ]; then
    jq '
      del(.statusLine) |
      .hooks.SessionStart = (
        (.hooks.SessionStart // []) |
        map(select(.hooks[0].command | test("plugin-tracker") | not))
      ) |
      .hooks.PostToolUse = (
        (.hooks.PostToolUse // []) |
        map(select(.hooks[0].command | test("plugin-tracker") | not))
      ) |
      if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end |
      if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end |
      if (.hooks | length) == 0 then del(.hooks) else . end
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    ok "settings.json — navbar keys removed"
  fi
fi

# ── 6. Clear plugin flags ─────────────────────────────────────────────────────
FLAG_DIR="/tmp/claude-plugin-flags"
if [ -d "$FLAG_DIR" ]; then
  rm -rf "$FLAG_DIR"
  ok "Plugin flags cleared ($FLAG_DIR)"
fi

# ── 7. Summary ────────────────────────────────────────────────────────────────
echo ""
say "Done! ✓"
echo ""
warn "Restart Claude Code to apply changes."
echo ""
