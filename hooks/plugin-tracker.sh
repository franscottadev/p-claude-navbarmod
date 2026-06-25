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
    if grep -qi "caveman" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
      touch "$FLAG_DIR/caveman.perm"
      log "session_start: wrote caveman.perm"
    fi
    ;;
  tool_use)
    mkdir -p "$FLAG_DIR"
    INPUT=$(cat)
    log "tool_use input: $INPUT"
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
    log "tool_use TOOL=$TOOL"
    case "$TOOL" in
      mcp__plugin_playwright_*) touch "$FLAG_DIR/playwright"; log "wrote playwright" ;;
      mcp__memo__*)             touch "$FLAG_DIR/memo";       log "wrote memo" ;;
    esac
    ;;
esac
