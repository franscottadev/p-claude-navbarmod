#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/^Claude //')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tok=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
output_tok=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

YELLOW=$(printf '\033[33m')
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
RESET=$(printf '\033[0m')

printf "%s" "$model"

if [ -n "$used_pct" ]; then
  pct=$(printf '%.0f' "$used_pct")
  if [ "$pct" -ge 80 ]; then
    color="$RED"
  elif [ "$pct" -ge 50 ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  printf " | ctx: %s%s%%%s" "$color" "$pct" "$RESET"
fi

if [ -n "$input_tok" ] && [ -n "$output_tok" ]; then
  printf " (in:%s out:%s)" "$input_tok" "$output_tok"
fi

total=$(( ${total_in:-0} + ${total_out:-0} ))
if [ "$total" -gt 0 ]; then
  printf " | sess: %s tok" "$total"
fi

if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  printf " |"
  [ -n "$five_pct" ] && printf " 5h:$(printf '%.0f' "$five_pct")%%"
  [ -n "$week_pct" ] && printf " 7d:$(printf '%.0f' "$week_pct")%%"
fi

FLAG_DIR="/tmp/claude-plugin-flags"
active=""
for flag in "$FLAG_DIR"/*; do
  [ -f "$flag" ] || continue
  name=$(basename "$flag")
  label="${name%.perm}"
  active="$active ${GREEN}● ${label}${RESET}"
done
if [ -n "$active" ]; then
  printf " |%s" "$active"
fi
