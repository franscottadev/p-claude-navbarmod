#!/bin/sh
set -e

REPO_URL="https://github.com/franscottadev/p-claude-navbarmod"
REPO_RAW="https://raw.githubusercontent.com/franscottadev/p-claude-navbarmod/main"
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
say "Claude Navbar Mod — Installer"
echo "────────────────────────────"

# ── Bootstrap: detect if running via curl pipe ────────────────────────────────
# When piped via `curl | bash`, $0 is "bash" or "sh" and local files don't exist.
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
BOOTSTRAPPED=0
CLONE_DIR=""

if [ ! -f "$SCRIPT_DIR/statusline-custom.sh" ]; then
  echo ""
  say "Fetching repo..."

  # Check deps
  if ! command -v git >/dev/null 2>&1; then
    err "git is required. Install git and try again."; exit 1
  fi

  CLONE_DIR="$(mktemp -d)/p-claude-navbarmod"
  git clone --depth=1 "$REPO_URL" "$CLONE_DIR" >/dev/null 2>&1
  ok "Cloned to $CLONE_DIR"
  SCRIPT_DIR="$CLONE_DIR"
  BOOTSTRAPPED=1
fi

REPO_DIR="$SCRIPT_DIR"

# ── Check deps ────────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  err "jq is required. Install with: brew install jq"; exit 1
fi

# ── 1. Scope ──────────────────────────────────────────────────────────────────
echo ""
echo "Install scope:"
echo "  1) Global  (~/.claude/)   — applies to all projects"
echo "  2) Project (.claude/)     — current project only"
echo ""
ask "Choose [1/2] (default: 1):"
read scope_choice
case "${scope_choice:-1}" in
  2) CLAUDE_DIR="$(pwd)/.claude" ;;
  *) CLAUDE_DIR="$HOME/.claude" ;;
esac
ok "Scope: $CLAUDE_DIR"

# ── 2. Preset ─────────────────────────────────────────────────────────────────
echo ""
echo "Available presets:"
echo "  1) claude-code   — model, ctx, tokens, rate limits, active plugins"
echo ""
ask "Choose preset [1] (default: 1):"
read preset_choice
PRESET="claude-code"
ok "Preset: $PRESET"

# ── 3. Skills check ───────────────────────────────────────────────────────────
echo ""
say "Checking required skills..."

SKILLS_DIR_GLOBAL="$HOME/.claude/skills"
SKILLS_DIR_LOCAL="$(pwd)/.claude/skills"
required_skills="caveman"
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
  echo "Install them from: https://github.com/anthropics/claude-code (Skills section)"
  echo "or copy .md files to $SKILLS_DIR_GLOBAL/"
  echo ""
  ask "Continue anyway? [y/N]:"
  read cont
  case "$cont" in
    y|Y) warn "Continuing — some features may not work" ;;
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
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

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

# ── 7. Cleanup cloned repo ────────────────────────────────────────────────────
if [ "$BOOTSTRAPPED" -eq 1 ] && [ -n "$CLONE_DIR" ]; then
  echo ""
  ask "Delete cloned repo? [Y/n]:"
  read del_choice
  case "${del_choice:-Y}" in
    n|N) ok "Kept at $CLONE_DIR" ;;
    *)   rm -rf "$CLONE_DIR"; ok "Repo deleted" ;;
  esac
fi

# ── 8. Summary ────────────────────────────────────────────────────────────────
echo ""
say "Done! ✓"
echo ""
echo "Installed:"
echo "  • $CLAUDE_DIR/statusline-custom.sh"
echo "  • $CLAUDE_DIR/hooks/plugin-tracker.sh"
echo "  • settings.json — statusLine + hooks patched"
echo ""
warn "Restart Claude Code to activate."
echo ""
