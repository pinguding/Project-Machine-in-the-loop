#!/usr/bin/env bash
#
# jarvis statusline — the "continuous" liveness signal for the /loop /jarvis watch.
#
# Reads the one-line .jarvis/status that jarvis writes each tick and paints the
# watch state in the Claude Code status line — visible even between ticks. If
# next_wake is long past with no update, it infers "stalled?" (the loop died or
# was stopped with Esc). When .jarvis/status is absent (= watch not running) it
# prints nothing, so it's harmless to leave always on.
#
# Enable (settings.json):
#   { "statusLine": { "type": "command",
#       "command": "bash ~/.claude/skills/jarvis/assets/statusline.sh" } }
#
set -euo pipefail

# Resolve the project dir: prefer current_dir/cwd from the stdin JSON, else PWD.
input="$(cat 2>/dev/null || true)"
dir="$(printf '%s' "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$dir" ] || dir="$(printf '%s' "$input" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$dir" ] || dir="$PWD"

status="$dir/.jarvis/status"
[ -f "$status" ] || exit 0   # watch not running → contribute nothing

state=; next_wake=; interval=; strength=; tick=
while read -r line; do
  for kv in $line; do
    case "$kv" in
      state=*)     state="${kv#*=}";;
      next_wake=*) next_wake="${kv#*=}";;
      interval=*)  interval="${kv#*=}";;
      strength=*)  strength="${kv#*=}";;
      tick=*)      tick="${kv#*=}";;
    esac
  done
done < "$status"

now="$(date +%s)"

# seconds -> compact human (3h / 11m / 40s)
hum(){
  local s="$1"; [ "$s" -lt 0 ] && s=$(( -s ))
  if   [ "$s" -ge 3600 ]; then printf '%dh' $(( s / 3600 ))
  elif [ "$s" -ge 60 ];   then printf '%dm' $(( s / 60 ))
  else                          printf '%ds' "$s"; fi
}

icon='🤖'
tail=""; [ -n "$strength" ] && tail=" · ${strength}"

# Event-based confirmation (priority): the Stop hook (loop-watch-hook.sh) drops .jarvis/stopped
# the moment the /jarvis wakeup is gone. If present, skip time inference and show "stopped" now.
if [ -f "$dir/.jarvis/stopped" ]; then
  printf '%s jarvis · ⚠ loop stopped — /loop /jarvis to resume%s' "$icon" "$tail"
  exit 0
fi

if [ -n "${next_wake:-}" ]; then
  remain=$(( next_wake - now ))
  grace=120                       # slack for a wake that fires a bit late
  if   [ "$remain" -gt 0 ];            then printf '%s jarvis · watching · next ~%s (%s)%s' "$icon" "$(hum "$remain")" "${interval:-?}" "$tail"
  elif [ "$remain" -ge $(( -grace )) ]; then printf '%s jarvis · checking…%s' "$icon" "$tail"
  else                                       printf '%s jarvis · ⚠ stalled? no tick for %s — /loop /jarvis to resume' "$icon" "$(hum "$remain")"; fi
else
  printf '%s jarvis · watching%s' "$icon" "$tail"
fi
