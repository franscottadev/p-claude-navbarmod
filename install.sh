#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
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

# ── 1. Scope ─────────────────────────────────────────────────────────────────
echo ""
say "Claude Navbar Mod — Installer"
echo "────────────────────────────"
echo ""
echo "Install scope:"
echo "  1) Global  (~/.claude/)      — applies to all projects"
echo "  2) Project (.claude/)        — current project only"
echo ""
ask "Choose [1/2] (default: 1):"
read scope_choice
case "${scope_choice:-1}" in
  2) CLAUDE_DIR="$(pwd)/.claude" ;;
  *) CLAUDE_DIR="$HOME/.claude" ;;
esac
ok "Scope: $CLAUDE_DIR"

# ── 2. Preset selection ───────────────────────────────────────────────────────
echo ""
echo "Available presets:"
echo "  1) claude-code   — model, ctx, tokens, rate limits, active plugins"
echo ""
ask "Choose preset [1] (default: 1):"
read preset_choice
PRESET="claude-code"
ok "Preset: $PRESET"
PRESET_DIR="$REPO_DIR/presets/$PRESET"

# ── 3. Required skills check ──────────────────────────────────────────────────
echo ""
say "Checking required skills..."

SKILLS_DIR_GLOBAL="$HOME/.claude/skills"
SKILLS_DIR_LOCAL="$(pwd)/.claude/skills"

required_skills="caveman"  # from preset.json — hardcoded for now

missing=""
for skill in $required_skills; do
  found=0
  [ -f "$SKILLS_DIR_GLOBAL/$skill.md" ] && found=1
  [ -f "$SKILLS_DIR_LOCAL/$skill.md" ]  && found=1
  if [ "$found" -eq 1 ]; then
    ok "Skill '$skill' found"
  else
    warn "Skill '$skill' not found"
    missing="$missing $skill"
  fi
done

if [ -n "$missing" ]; then
  echo ""
  warn "Missing skills:$missing"
  echo ""
  echo "Skills must be installed to continue."
  echo "Install them from: https://github.com/anthropics/claude-code (Skills section)"
  echo "or copy .md skill files to $SKILLS_DIR_GLOBAL/"
  echo ""
  ask "Continue anyway? [y/N]:"
  read cont
  case "$cont" in
    y|Y) warn "Continuing without required skills — some features may not work" ;;
    *)   err "Aborted."; exit 1 ;;
  esac
fi

# ── 4. Backup ─────────────────────────────────────────────────────────────────
echo ""
say "Backing up existing files..."

BACKUP_DIR="$CLAUDE_DIR/backups/navbar-mod-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  [ -f "$1" ] && cp "$1" "$BACKUP_DIR/" && ok "Backed up $(basename "$1")"
}
backup_if_exists "$CLAUDE_DIR/statusline-custom.sh"
backup_if_exists "$CLAUDE_DIR/hooks/plugin-tracker.sh"
backup_if_exists "$CLAUDE_DIR/settings.json"
ok "Backups in $BACKUP_DIR"

# ── 5. Copy files ─────────────────────────────────────────────────────────────
echo ""
say "Installing files..."

mkdir -p "$CLAUDE_DIR/hooks"
cp "$REPO_DIR/statusline-custom.sh" "$CLAUDE_DIR/statusline-custom.sh"
chmod +x "$CLAUDE_DIR/statusline-custom.sh"
ok "statusline-custom.sh"

cp "$REPO_DIR/hooks/plugin-tracker.sh" "$CLAUDE_DIR/hooks/plugin-tracker.sh"
chmod +x "$CLAUDE_DIR/hooks/plugin-tracker.sh"
ok "hooks/plugin-tracker.sh"

# ── 6. Patch settings.json ────────────────────────────────────────────────────
echo ""
say "Patching settings.json..."

SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Use jq to merge — preserves existing keys, adds/updates navbar keys
TRACKER="sh $CLAUDE_DIR/hooks/plugin-tracker.sh"
STATUSLINE="sh $CLAUDE_DIR/statusline-custom.sh"

jq \
  --arg tracker "$TRACKER" \
  --arg statusline "$STATUSLINE" \
  '
  .statusLine = {"type": "command", "command": $statusline} |
  .hooks.SessionStart = (
    (.hooks.SessionStart // []) |
    map(select(.hooks[0].command | test("plugin-tracker") | not)) +
    [{"matcher": "", "hooks": [{"type": "command", "command": ($tracker + " session_start")}]}]
  ) |
  .hooks.PostToolUse = (
    (.hooks.PostToolUse // []) |
    map(select(.hooks[0].command | test("plugin-tracker") | not)) +
    [{"matcher": "", "hooks": [{"type": "command", "command": ($tracker + " tool_use")}]}]
  )
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
ok "settings.json patched"

# ── 7. Summary ────────────────────────────────────────────────────────────────
echo ""
say "Done! ✓"
echo ""
echo "What was installed:"
echo "  • $CLAUDE_DIR/statusline-custom.sh"
echo "  • $CLAUDE_DIR/hooks/plugin-tracker.sh"
echo "  • settings.json — statusLine + SessionStart + PostToolUse hooks"
echo ""
warn "Restart Claude Code to activate the changes."
echo ""
