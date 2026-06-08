#!/usr/bin/env bash
#
# jarvis statusline — /loop /jarvis 워치의 "연속" 생존 신호.
#
# 매 tick에서 jarvis가 기록하는 .jarvis/status 한 줄을 읽어, tick과 tick
# 사이에도 Claude Code 하단 상태줄에 워치 상태를 그린다. next_wake 시각이
# 한참 지났는데 갱신이 없으면 "멈춤?"으로 추론한다(루프가 죽었거나 Esc로 정지).
# .jarvis/status 가 없으면(=워치 미가동) 아무것도 출력하지 않으므로 항상 켜둬도 무해하다.
#
# 활성화(settings.json):
#   { "statusLine": { "type": "command",
#       "command": "bash ~/.claude/skills/jarvis/assets/statusline.sh" } }
#
set -euo pipefail

# 프로젝트 디렉토리 해석: stdin JSON의 current_dir/cwd 우선, 없으면 PWD.
input="$(cat 2>/dev/null || true)"
dir="$(printf '%s' "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$dir" ] || dir="$(printf '%s' "$input" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$dir" ] || dir="$PWD"

status="$dir/.jarvis/status"
[ -f "$status" ] || exit 0   # 워치 미가동 → 상태줄에 아무것도 안 보탬

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

# 초 → 짧은 사람 표기(3h / 11m / 40s)
hum(){
  local s="$1"; [ "$s" -lt 0 ] && s=$(( -s ))
  if   [ "$s" -ge 3600 ]; then printf '%dh' $(( s / 3600 ))
  elif [ "$s" -ge 60 ];   then printf '%dm' $(( s / 60 ))
  else                          printf '%ds' "$s"; fi
}

icon='🤖'
tail=""; [ -n "$strength" ] && tail=" · ${strength}"

if [ -n "${next_wake:-}" ]; then
  remain=$(( next_wake - now ))
  grace=120                       # wake가 조금 늦게 발화하는 여유
  if   [ "$remain" -gt 0 ];            then printf '%s jarvis · 감시 중 · 다음 ~%s (%s)%s' "$icon" "$(hum "$remain")" "${interval:-?}" "$tail"
  elif [ "$remain" -ge $(( -grace )) ]; then printf '%s jarvis · 확인 중…%s' "$icon" "$tail"
  else                                       printf '%s jarvis · ⚠ 멈춤? %s 동안 tick 없음 — /loop /jarvis 로 재개' "$icon" "$(hum "$remain")"; fi
else
  printf '%s jarvis · 감시 중%s' "$icon" "$tail"
fi
