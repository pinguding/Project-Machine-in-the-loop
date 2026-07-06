#!/usr/bin/env bash
# jarvis 워치 "기계적 핵심" 테스트 — SKILL.md 절차 1~3의 측정·게이트·경계 판단을
# 실제 git 명령으로 샌드박스 레포에서 재현해 검증한다.
#
# 모델이 해석하는 부분(navigator 리뷰, debounce/active_chat, mirror, ScheduleWakeup)은
# 여기서 테스트하지 않는다 — 그건 실제 /loop /jarvis 호출에서만 검증 가능하다.
# 여기서 보는 것: shortstat 파싱, delta 계산, 새 변경 게이트/위험 게이트, 커밋경계·되돌림 감지,
#   stale base_head 자가보정(절차 2(0)), no-arg 시 .jarvis/args 자동 복원(절차 0.4).
# (고정 라인/파일 임계값은 제거됨 — 직전 리뷰 이후 새 변경이 1줄이라도 쌓이면 게이트 충족.)
set -uo pipefail

# repo root (captured before we cd into the sandbox) — used to locate statusline.sh
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
cd "$SANDBOX"
git init -q
git config user.name t; git config user.email t@t
git commit -q --allow-empty -m init

PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then PASS=$((PASS+1)); printf '  ✅ %s  (=%s)\n' "$3" "$1"; else FAIL=$((FAIL+1)); printf '  ❌ %s  expected %s got %s\n' "$3" "$2" "$1"; fi; }

# SKILL 절차 1: 추적 변경 + 미추적(새) 파일을 합산 → lines
# 주의: `git diff --shortstat HEAD`는 미추적 파일을 포함하지 않으므로,
# `git ls-files --others`로 새 파일을 따로 세어 더한다(인덱스는 건드리지 않음).
# (파일 개수도 함께 돌려주지만, 게이트는 더 이상 파일 수를 쓰지 않는다.)
measure(){ # args: optional `-- pathspec...`
  local out tf ti td list uf ul
  out="$(git diff --shortstat HEAD "$@" 2>/dev/null)"
  tf=$(printf '%s' "$out" | grep -oE '[0-9]+ files? changed' | grep -oE '[0-9]+'); tf=${tf:-0}
  ti=$(printf '%s' "$out" | grep -oE '[0-9]+ insertions?' | grep -oE '[0-9]+'); ti=${ti:-0}
  td=$(printf '%s' "$out" | grep -oE '[0-9]+ deletions?'  | grep -oE '[0-9]+'); td=${td:-0}
  list="$(git ls-files --others --exclude-standard "$@" 2>/dev/null)"
  uf=0; ul=0
  if [ -n "$list" ]; then
    uf=$(printf '%s\n' "$list" | sed '/^$/d' | wc -l | tr -d ' ')
    ul=$(printf '%s\n' "$list" | sed '/^$/d' | while IFS= read -r f; do [ -f "$f" ] && wc -l < "$f"; done | awk '{s+=$1} END{print s+0}')
  fi
  echo "$((tf+uf)) $((ti+td+ul))"   # files, lines (추적+미추적)
}

# 새 변경 게이트: 직전 리뷰 기준선(base_lines) 이후 라인이 늘었으면 충족. 고정 임계값 없음.
gate(){ [ "$(( $1 - $2 ))" -ge 1 ] && echo 1 || echo 0; }   # gate <cur_lines> <base_lines>

echo "▸ 1. 변경 없음 → 게이트 미충족 (delta=0)"
base_lines=0
read -r cf cl < <(measure)
ok "$cl" 0 "cur_lines"
ok "$(gate "$cl" "$base_lines")" 0 "gate_met"

echo "▸ 2. 10라인 추가 → 새 변경 → 게이트 충족 (분량 무관)"
printf 'line\n%.0s' {1..10} > a.txt
read -r cf cl < <(measure)
ok "$cl" 10 "cur_lines"
ok "$(gate "$cl" "$base_lines")" 1 "gate_met (새 변경 10라인 — 임계값 없이 충족)"

echo "▸ 3. 리뷰 후 base 갱신 → 변경 그대로 → 새 변경 없음 → 미충족"
base_lines=$cl   # jarvis-once 실행(flush) 시 base_lines = cur_lines 로 흡수
read -r cf cl < <(measure)
ok "$(gate "$cl" "$base_lines")" 0 "gate_met (같은 변경 반복 리뷰 안 함)"

echo "▸ 4. 5라인 더 추가(총 15) → 새 변경 누적 → 다시 충족"
printf 'line\n%.0s' {1..15} > a.txt
read -r cf cl < <(measure)
ok "$cl" 15 "cur_lines"
ok "$(gate "$cl" "$base_lines")" 1 "gate_met (delta=5)"
git add -A; git commit -q -m base   # 기준 커밋(working tree 비움)

echo "▸ 5. 위험 경로 1줄 → 분량 무관 위험 게이트"
mkdir -p src
printf 'charge()\n' > src/payment_service.js
read -r rf rl < <(measure -- '**/*payment*' 'src/*payment*')
ok "$rl" 1 "risk_lines (1줄)"
risk_gate=$([ "$rl" -ge 1 ] && echo 1 || echo 0)
ok "$risk_gate" 1 "risk_gate (1줄이라도 발화)"
git add -A; git commit -q -m pay

echo "▸ 6. 커밋 경계 — HEAD 변동 감지 (working tree는 깨끗)"
base_head="$(git rev-parse 'HEAD~1')"
cur_head="$(git rev-parse HEAD)"
boundary=$([ -n "$base_head" ] && [ "$cur_head" != "$base_head" ] && echo 1 || echo 0)
ok "$boundary" 1 "commit_boundary (head 변동)"
read -r cf cl < <(measure)
ok "$cl" 0 "working tree clean (커밋 후 0)"

echo "▸ 7. 되돌림(discard) 감지 — cur_lines < base_lines"
base_lines=15   # 직전 baseline에 기록돼 있던 값(a.txt 15라인 시점)
printf 'line\n%.0s' {1..5} > a.txt   # 15 → 5로 되돌림 (10줄 삭제)
read -r cf cl < <(measure)
discard=$([ "$cl" -lt "$base_lines" ] && echo 1 || echo 0)
ok "$discard" 1 "discard_detected (cur=$cl < base=$base_lines)"

echo "▸ 8. baseline 직렬화/역직렬화 라운드트립 (files 필드 없음)"
mkdir -p .jarvis
printf 'lines=15 risk=1 head=%s deferred=0 boot=3 mirrored=0\n' "$cur_head" > .jarvis/baseline
# 역직렬화 (SKILL 형식 그대로 key=value 파싱)
eval "$(sed -E 's/([a-z]+)=([^ ]*)/local_\1="\2";/g' .jarvis/baseline)"
ok "$local_lines" 15 "baseline lines 파싱"
ok "$local_boot" 3 "baseline boot 파싱"
ok "$local_mirrored" 0 "baseline mirrored 파싱(신규 필드)"
ok "$local_head" "$cur_head" "baseline head 파싱"

echo "▸ 9. stale base_head 자가보정 (절차 2(0)) — 레포에 없는 SHA면 baseline 리셋"
# SKILL: base_head가 비어있지 않을 때 `git cat-file -e <base_head>^{commit}`로 존재 확인.
#        존재하지 않으면(rebase/reset/branch 삭제) baseline을 현재값으로 조용히 리셋.
head_exists(){ git cat-file -e "$1^{commit}" 2>/dev/null && echo 1 || echo 0; }
# (a) 유효한 head → 존재 → 리셋 안 함
ok "$(head_exists "$cur_head")" 1 "valid base_head 존재 인식"
# (b) 레포에 없는 SHA → 미존재 → stale
bogus="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
ok "$(head_exists "$bogus")" 0 "stale base_head 미존재 인식"
# (c) stale 감지 시 baseline을 현재 측정값으로 리셋하는 분기
printf 'line\n%.0s' {1..7} > a.txt   # 현재 워킹트리 변경 7라인
read -r cf cl < <(measure)
base_head="$bogus"
if [ -n "$base_head" ] && [ "$(head_exists "$base_head")" = 0 ]; then
  # 리셋: lines=cur_lines head=cur_head deferred=0 (boot/mirrored 보존), jarvis-once 미실행
  reset_lines=$cl; reset_head="$(git rev-parse HEAD)"; reset_did_review=0
fi
ok "${reset_lines:-X}" "$cl" "stale → baseline.lines = cur_lines 로 리셋"
ok "${reset_head:-X}" "$(git rev-parse HEAD)" "stale → baseline.head = cur_head 로 리셋"
ok "${reset_did_review:-X}" 0 "stale 리셋 시 jarvis-once 미실행"
git checkout -q -- a.txt 2>/dev/null; rm -f a.txt

echo "▸ 10. no-arg 시작 → .jarvis/args 자동 복원 (절차 0.4) — 명시 > 저장 > 기본"
mkdir -p .jarvis
# SKILL 절차 0.4: 인식된 args가 하나도 없고 .jarvis/args가 있으면 그 값을 유효 args로.
resolve_args(){ # $1 = 명시적으로 받은 args (없으면 빈 문자열)
  if [ -n "$1" ]; then printf '%s' "$1"
  elif [ -f .jarvis/args ]; then cat .jarvis/args
  else printf 'strength=medium'; fi
}
printf 'strength=high idle=30m' > .jarvis/args
# (a) 명시 args 없음 + 저장 있음 → 저장값 복원 (재개)
ok "$(resolve_args '')" "strength=high idle=30m" "no-arg → .jarvis/args 복원"
# (b) 명시 args 있음 → 저장 무시, 명시 우선
ok "$(resolve_args 'strength=low')" "strength=low" "명시 args > 저장 args"
# (c) 명시 없음 + 저장 없음 → 기본 medium
rm -f .jarvis/args
ok "$(resolve_args '')" "strength=medium" "저장 없음 → 기본 medium"

echo "▸ 11. statusline.sh 렌더링 (생존 신호) — .jarvis/status → 감시중/확인중/멈춤?/미가동"
# SKILL 절차 4가 기록하는 .jarvis/status 한 줄을 statusline.sh가 어떻게 그리는지 검증.
# en/ko 둘 다 같은 상태 토큰을 읽으므로 en 스크립트로 로직을 본다(문구만 언어별 차이).
SL="$REPO_DIR/skills/en/jarvis/assets/statusline.sh"
contains(){ case "$2" in *"$1"*) echo 1;; *) echo 0;; esac; }
if [ -f "$SL" ]; then
  now=$(date +%s)
  # (a) 미래 next_wake → "watching" + 상대 ETA
  printf 'state=watching next_wake=%s interval=active strength=medium tick=%s\n' "$((now+180))" "$now" > .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'watching' "$out")" 1 "미래 wake → watching"
  ok "$(contains '~3m' "$out")"     1 "watching → 상대 ETA(~3m) 표기"
  # (b) 막 지난 wake(grace 안) → "checking…"
  printf 'state=watching next_wake=%s interval=active strength=high tick=%s\n' "$((now-30))" "$((now-30))" > .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'checking' "$out")" 1 "grace 내 경과 → checking…"
  # (c) 한참 지난 wake → "stalled?"
  printf 'state=watching next_wake=%s interval=idle strength=low tick=%s\n' "$((now-700))" "$((now-700))" > .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'stalled' "$out")" 1 "next_wake 한참 경과 → stalled?"
  # (d) status 파일 없음 → 아무것도 출력 안 함(항상 켜둬도 무해)
  rm -f .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "${#out}" 0 "status 없음 → 빈 출력"
else
  echo "  ⚠ statusline.sh 없음 — 스킵 ($SL)"
fi

echo "▸ 12. loop-watch-hook.sh (Stop 훅) — session_crons 기반 이벤트 멈춤 감지"
# Stop 훅 payload의 session_crons에 /jarvis wake가 없으면 .jarvis/stopped 를 남기고,
# 있으면 지운다. last_assistant_message에 /jarvis 텍스트가 있어도 오탐 없어야 한다.
HK="$REPO_DIR/skills/en/jarvis/assets/loop-watch-hook.sh"
if [ -f "$HK" ]; then
  printf 'state=watching next_wake=9999999999 interval=active strength=high tick=1\n' > .jarvis/status
  # (a) /jarvis wake 없음 → stopped 생성
  printf '{"hook_event_name":"Stop","cwd":"%s","session_crons":[],"last_assistant_message":"talking about /jarvis"}' "$SANDBOX" | bash "$HK"
  ok "$([ -f .jarvis/stopped ] && echo 1 || echo 0)" 1 "wake 없음 → .jarvis/stopped 생성"
  # statusline이 플래그를 우선 인식 → 즉시 stopped (next_wake가 먼 미래여도)
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'stopped' "$out")" 1 "stopped 플래그 → statusline 즉시 멈춤(시간추론 무시)"
  # (b) /jarvis wake 있음 → stopped 해제
  printf '{"hook_event_name":"Stop","cwd":"%s","session_crons":[{"prompt":"/loop /jarvis strength=high"}]}' "$SANDBOX" | bash "$HK"
  ok "$([ -f .jarvis/stopped ] && echo 1 || echo 0)" 0 "wake 있음 → .jarvis/stopped 해제"
  # (c) last_assistant_message에만 /jarvis (crons는 비어있음) → 오탐 없이 stopped
  printf '{"hook_event_name":"Stop","cwd":"%s","session_crons":[{"prompt":"/some-other-loop"}],"last_assistant_message":"/jarvis /jarvis"}' "$SANDBOX" | bash "$HK"
  ok "$([ -f .jarvis/stopped ] && echo 1 || echo 0)" 1 "메시지 텍스트 /jarvis 오탐 없음(crons만 판정)"
  # (d) session_crons 필드 없음 → unknown(손대지 않음)
  rm -f .jarvis/stopped
  printf '{"hook_event_name":"Stop","cwd":"%s"}' "$SANDBOX" | bash "$HK"
  ok "$([ -f .jarvis/stopped ] && echo 1 || echo 0)" 0 "session_crons 없음 → no-op(시간추론에 위임)"
  rm -f .jarvis/status .jarvis/stopped
else
  echo "  ⚠ loop-watch-hook.sh 없음 — 스킵 ($HK)"
fi

echo "▸ 13. 계획 모드 — checklist.md 감지 + 진행률 카운트 + statusline plan 구획"
# SKILL 절차 4가 쓰는 진행률 카운트(POSIX 클래스, macOS BSD grep 호환)와
# checklist.md 존재 = 계획 모드 활성 판정, statusline의 `· plan N/M` 렌더링을 본다.
mkdir -p .jarvis
# (a) checklist 없음 → 계획 모드 비활성
plan_active=$([ -f .jarvis/checklist.md ] && echo 1 || echo 0)
ok "$plan_active" 0 "checklist 없음 → 계획 모드 비활성"
# (b) checklist 생성 → 진행률 카운트 (done/total)
cat > .jarvis/checklist.md <<'CL'
# Checklist — demo
## phase 1
- [x] done item
- [X] also done
- [ ] ▶ not yet
  - [ ] indented sub
## phase 2
- [ ] another
CL
count_done(){ grep -cE '^[[:space:]]*-[[:space:]]*\[[xX]\]' .jarvis/checklist.md; }
count_total(){ grep -cE '^[[:space:]]*-[[:space:]]*\[[ xX]\]' .jarvis/checklist.md; }
plan_active=$([ -f .jarvis/checklist.md ] && echo 1 || echo 0)
ok "$plan_active" 1 "checklist 존재 → 계획 모드 활성"
ok "$(count_done)"  2 "완료 항목 카운트([x]/[X])"
ok "$(count_total)" 5 "전체 항목 카운트([ ]/[x])"
# (c) statusline이 plan 필드를 `· plan N/M` 로 렌더
if [ -f "$SL" ]; then
  now=$(date +%s)
  printf 'state=watching next_wake=%s interval=active strength=medium plan=2/5 tick=%s\n' "$((now+180))" "$now" > .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'plan 2/5' "$out")" 1 "statusline → · plan 2/5 표기"
  # (d) plan 필드 없음 → plan 구획 미표기
  printf 'state=watching next_wake=%s interval=active strength=medium tick=%s\n' "$((now+180))" "$now" > .jarvis/status
  out="$(printf '{"workspace":{"current_dir":"%s"}}' "$SANDBOX" | bash "$SL")"
  ok "$(contains 'plan' "$out")" 0 "plan 필드 없음 → plan 구획 없음"
  rm -f .jarvis/status
fi
rm -f .jarvis/checklist.md

echo ""
echo "════════════════════════════════════"
echo "  PASS=$PASS  FAIL=$FAIL"
echo "════════════════════════════════════"
[ "$FAIL" -eq 0 ]
