#!/usr/bin/env bash
#
# jarvis loop-watch hook — event-based confirmation that the loop has died, via the Stop hook.
#
# The Stop hook fires at the end of every turn and provides payload.session_crons (the list of
# currently scheduled wakeups). If no /jarvis wakeup is in it, the loop is no longer scheduled
# (a missed/errored ScheduleWakeup, or an Esc-killed loop followed by any user turn). In that
# case write .jarvis/stopped so statusline.sh shows "stopped" instantly, with no time inference.
# If a wakeup is alive, clear the flag.
#
# Limit: the Stop hook does NOT fire on the Esc interrupt itself (official docs). So the only
# case it misses is "pressed Esc and walked away with no further turn" — that one is caught by
# statusline.sh's time inference (grace).
#
# Register in settings.json:
#   "hooks": { "Stop":        [ { "hooks": [ { "type": "command",
#                "command": "bash ~/.claude/skills/jarvis/assets/loop-watch-hook.sh" } ] } ],
#              "StopFailure":  [ { "hooks": [ { "type": "command",
#                "command": "bash ~/.claude/skills/jarvis/assets/loop-watch-hook.sh" } ] } ] }
#
set -uo pipefail

payload="$(cat 2>/dev/null || true)"

# Parse cwd and "is a /jarvis wakeup scheduled?" in one pass (JSON via python3 for safety).
# Output: "<cwd>\t<yes|no|unknown>"  — on parse failure, unknown (do nothing → time-inference fallback).
parsed="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("\tunknown"); sys.exit(0)
cwd = d.get("cwd", "") or ""
crons = d.get("session_crons")
if crons is None:
    print(cwd + "\tunknown"); sys.exit(0)
hit = any("/jarvis" in ((c or {}).get("prompt") or "") for c in crons)
print(cwd + "\t" + ("yes" if hit else "no"))
' 2>/dev/null)"

dir="${parsed%%	*}"          # before tab = cwd
pending="${parsed##*	}"      # after tab  = yes|no|unknown
[ -n "$dir" ] || dir="$PWD"

# Only act when a watch is active in this project.
[ -f "$dir/.jarvis/status" ] || exit 0

case "$pending" in
  yes) rm -f "$dir/.jarvis/stopped" ;;                                   # wakeup alive → clear stopped flag
  no)  printf 'stopped_at=%s reason=no-jarvis-wake\n' "$(date +%s)" \
         > "$dir/.jarvis/stopped" ;;                                     # no /jarvis wakeup → confirm stopped
  *)   : ;;                                                              # unknown → leave as-is (time inference)
esac
exit 0
