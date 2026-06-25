#!/bin/sh
# plugin-tracker.sh <event>
# PostToolUse passes JSON on stdin
EVENT="$1"
FLAG_DIR="/tmp/claude-plugin-flags"

if [ "${DEBUG:-0}" = "1" ]; then
  LOG="/tmp/navbar-debug.log"
  log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$1" >> "$LOG"; }
else
  log() { :; }
fi

case "$EVENT" in
  session_start)
    rm -rf "$FLAG_DIR"
    mkdir -p "$FLAG_DIR"
    # Detect any installed skills referenced in CLAUDE.md → permanent flags
    SKILLS_DIR="$HOME/.claude/skills"
    CLAUDE_MD="$HOME/.claude/CLAUDE.md"
    if [ -d "$SKILLS_DIR" ] && [ -f "$CLAUDE_MD" ]; then
      for skill_file in "$SKILLS_DIR"/*.md; do
        [ -f "$skill_file" ] || continue
        skill=$(basename "$skill_file" .md)
        if grep -qi "$skill" "$CLAUDE_MD" 2>/dev/null; then
          touch "$FLAG_DIR/${skill}.perm"
          log "session_start: wrote ${skill}.perm"
        fi
      done
    fi
    ;;
  tool_use)
    mkdir -p "$FLAG_DIR"
    INPUT=$(cat)
    log "tool_use input: $INPUT"
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
    log "tool_use TOOL=$TOOL"
    # Extract plugin name generically from mcp__<plugin>__<action>
    # Strip leading "plugin_" prefix if present (e.g. mcp__plugin_playwright_playwright__*)
    case "$TOOL" in
      mcp__*)
        plugin=$(printf '%s' "$TOOL" | sed 's/^mcp__//; s/__.*//; s/^plugin_//')
        if [ -n "$plugin" ]; then
          touch "$FLAG_DIR/$plugin"
          log "wrote flag: $plugin"
        fi
        ;;
    esac
    ;;
esac
