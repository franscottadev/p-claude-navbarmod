#!/bin/sh
# plugin-tracker.sh <event>
# PostToolUse passes JSON on stdin with tool_name field
EVENT="$1"
FLAG_DIR="/tmp/claude-plugin-flags"

case "$EVENT" in
  session_start)
    rm -rf "$FLAG_DIR"
    mkdir -p "$FLAG_DIR"
    if grep -qi "caveman" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
      touch "$FLAG_DIR/caveman.perm"
    fi
    ;;
  tool_use)
    mkdir -p "$FLAG_DIR"
    TOOL=$(cat | jq -r '.tool_name // empty' 2>/dev/null)
    case "$TOOL" in
      mcp__plugin_playwright_*) touch "$FLAG_DIR/playwright" ;;
      mcp__memo__*)             touch "$FLAG_DIR/memo" ;;
    esac
    ;;
esac
