#!/usr/bin/env bash
# jarvis 워치 "기계적 핵심" 테스트 — SKILL.md 절차 1~3의 측정·게이트·경계 판단을
# 실제 git 명령으로 샌드박스 레포에서 재현해 검증한다.
#
# 모델이 해석하는 부분(navigator 리뷰, debounce/active_chat, mirror, ScheduleWakeup)은
# 여기서 테스트하지 않는다 — 그건 실제 /jarvis 호출에서만 검증 가능하다.
# 여기서 보는 것: shortstat 파싱, delta 계산, 임계값/파일/위험 게이트, 커밋경계·되돌림 감지.
set -uo pipefail

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
cd "$SANDBOX"
git init -q
git config user.name t; git config user.email t@t
git commit -q --allow-empty -m init

PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then PASS=$((PASS+1)); printf '  ✅ %s  (=%s)\n' "$3" "$1"; else FAIL=$((FAIL+1)); printf '  ❌ %s  expected %s got %s\n' "$3" "$2" "$1"; fi; }

# SKILL 절차 1: 추적 변경 + 미추적(새) 파일을 합산 → lines, files
# 주의: `git diff --shortstat HEAD`는 미추적 파일을 포함하지 않으므로,
# `git ls-files --others`로 새 파일을 따로 세어 더한다(인덱스는 건드리지 않음).
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

THRESHOLD=50; FILES=2

echo "▸ 1. 변경 없음 → 게이트 미충족"
read -r cf cl < <(measure)
ok "$cl" 0 "cur_lines"
gate=$([ "$cl" -ge "$THRESHOLD" ] || [ "$cf" -ge "$FILES" ] && echo 1 || echo 0)
ok "$gate" 0 "gate_met"

echo "▸ 2. 10라인 추가 → 임계값(50) 미달"
printf 'line\n%.0s' {1..10} > a.txt
read -r cf cl < <(measure)
ok "$cl" 10 "cur_lines"
gate=$( { [ "$cl" -ge "$THRESHOLD" ] || [ "$cf" -ge "$FILES" ]; } && echo 1 || echo 0)
ok "$gate" 0 "gate_met (라인 미달, 파일 1개)"

echo "▸ 3. 60라인으로 증가 → 임계값 초과 → 게이트 충족"
printf 'line\n%.0s' {1..60} > a.txt
read -r cf cl < <(measure)
ok "$cl" 60 "cur_lines"
gate=$( { [ "$cl" -ge "$THRESHOLD" ] || [ "$cf" -ge "$FILES" ]; } && echo 1 || echo 0)
ok "$gate" 1 "gate_met (라인 초과)"

echo "▸ 4. 작은 변경이지만 2파일 → files 게이트(OR)로 충족"
git add -A; git commit -q -m base   # 기준 커밋(working tree 비움)
printf 'x\n' > b.txt; printf 'y\n' > c.txt
read -r cf cl < <(measure)
ok "$cf" 2 "cur_files"
gate=$( { [ "$cl" -ge "$THRESHOLD" ] || [ "$cf" -ge "$FILES" ]; } && echo 1 || echo 0)
ok "$gate" 1 "gate_met (파일 수 OR)"
git add -A; git commit -q -m two

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
base_lines=60   # 직전 baseline에 기록돼 있던 값(시나리오 3)
printf 'line\n%.0s' {1..5} > a.txt   # 60 → 5로 되돌림
read -r cf cl < <(measure)
discard=$([ "$cl" -lt "$base_lines" ] && echo 1 || echo 0)
ok "$discard" 1 "discard_detected (cur=$cl < base=$base_lines)"

echo "▸ 8. baseline 직렬화/역직렬화 라운드트립"
mkdir -p .jarvis
printf 'lines=60 files=2 risk=1 head=%s deferred=0 boot=3 mirrored=0\n' "$cur_head" > .jarvis/baseline
# 역직렬화 (SKILL 형식 그대로 key=value 파싱)
eval "$(sed -E 's/([a-z]+)=([^ ]*)/local_\1="\2";/g' .jarvis/baseline)"
ok "$local_lines" 60 "baseline lines 파싱"
ok "$local_boot" 3 "baseline boot 파싱"
ok "$local_mirrored" 0 "baseline mirrored 파싱(신규 필드)"
ok "$local_head" "$cur_head" "baseline head 파싱"

echo ""
echo "════════════════════════════════════"
echo "  PASS=$PASS  FAIL=$FAIL"
echo "════════════════════════════════════"
[ "$FAIL" -eq 0 ]
