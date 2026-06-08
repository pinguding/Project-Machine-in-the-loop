#!/usr/bin/env bash
#
# jarvis loop-watch hook — Stop 훅으로 "루프 죽음"을 이벤트 기반으로 확정한다.
#
# Stop 훅은 매 턴 끝에 발화하며 payload.session_crons(현재 예약된 wake 목록)를 준다.
# 그 안에 /jarvis wake가 없으면 = 루프가 더는 예약돼 있지 않다(ScheduleWakeup 누락·에러,
# 또는 Esc로 죽은 뒤 사용자가 아무 입력이나 보낸 턴). 이때 .jarvis/stopped 를 남겨
# statusline.sh 가 시간 추론 없이 즉시 "멈춤"을 표시하게 한다. wake가 살아있으면 플래그를 지운다.
#
# 한계: Stop 훅은 Esc 인터럽트 그 자체엔 발화하지 않는다(공식 문서). 그래서 "Esc 누르고
# 아무 턴도 안 생긴 채 자리를 뜬" 경우만 못 잡고, 그건 statusline 의 시간 추론(grace)이 받는다.
#
# settings.json 등록:
#   "hooks": { "Stop":        [ { "hooks": [ { "type": "command",
#                "command": "bash ~/.claude/skills/jarvis/assets/loop-watch-hook.sh" } ] } ],
#              "StopFailure":  [ { "hooks": [ { "type": "command",
#                "command": "bash ~/.claude/skills/jarvis/assets/loop-watch-hook.sh" } ] } ] }
#
set -uo pipefail

payload="$(cat 2>/dev/null || true)"

# payload에서 cwd 와 "/jarvis wake가 예약돼 있나"를 한 번에 파싱(JSON은 python3로 안전하게).
# 출력: "<cwd>\t<yes|no|unknown>"  — 파싱 실패면 unknown(아무 것도 안 함 → 시간추론 fallback).
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

dir="${parsed%%	*}"          # 탭 앞 = cwd
pending="${parsed##*	}"      # 탭 뒤 = yes|no|unknown
[ -n "$dir" ] || dir="$PWD"

# 이 프로젝트에 워치가 떠 있을 때만 관여한다.
[ -f "$dir/.jarvis/status" ] || exit 0

case "$pending" in
  yes) rm -f "$dir/.jarvis/stopped" ;;                                   # wake 살아있음 → 멈춤 플래그 해제
  no)  printf 'stopped_at=%s reason=no-jarvis-wake\n' "$(date +%s)" \
         > "$dir/.jarvis/stopped" ;;                                     # /jarvis wake 없음 → 멈춤 확정
  *)   : ;;                                                              # unknown → 손대지 않음(시간추론에 맡김)
esac
exit 0
