---
name: jarvis-resume
description: /jarvis-pause로 멈춘 jarvis 워치 wake 루프를 다시 시작한다. .jarvis/args에 저장된 직전 설정(strength 등)을 복원해 같은 강도로 이어서 돈다. "jarvis 재개", "워치 다시 켜", "jarvis resume" 요청 시 사용.
---

# jarvis-resume

`/jarvis-pause`으로 멈춰 둔 워치를 **다시 켠다.** `.jarvis/paused` 플래그를 지우고, 저장돼 있던 설정(`.jarvis/args`)으로 `jarvis` 첫 tick을 돌려 루프를 되살린다.

> baseline이 보존돼 있으므로 멈춘 지점부터 이어서 감시한다(변경 누적도 그대로). 완전 초기화 상태에서 새로 시작하려면 `/jarvis` 또는 (먼저 초기화 후) `/jarvis-stop` → `/jarvis`를 쓴다.

## 절차

1. **일시정지 플래그 제거**:

   ```bash
   rm -f .jarvis/paused
   ```

2. **저장된 설정 복원**: `.jarvis/args`가 있으면 그 한 줄을 읽어 args로 쓴다. 없으면(이전에 stop했거나 처음) args 없이 medium 기본으로 시작한다.

   ```bash
   cat .jarvis/args 2>/dev/null || true
   ```

3. **루프 재시작**: 복원한 args로 `jarvis` 스킬을 호출한다 — `Skill('jarvis', args=<복원한 args>)`. (args가 비어 있으면 인자 없이 `Skill('jarvis')`.)
   - 이 호출이 jarvis 첫 tick을 수행하고, 그 tick이 절차 4에서 다시 `ScheduleWakeup`을 걸어 self-paced 루프가 이어진다.
   - baseline이 이미 있으므로 시작 배너(절차 0.5)와 강도 질문(절차 0.6)은 자동으로 건너뛴다 — 조용히 재개된다.

4. **보고** (한 줄): `▶ Jarvis 워치 재개 (<복원한 strength 등>). 이어서 감시 중.`

## 엣지 케이스

- **`.jarvis/paused`가 애초에 없던 경우**: 이미 돌고 있거나 멈춰 있던 상태. 그래도 무해하게 `Skill('jarvis')`로 한 tick을 돌려 루프를 보장한다(중복 예약은 jarvis가 tick당 1회만 걸므로 안전).
- **`.jarvis/baseline`도 없는 경우**: 완전 초기 상태 → `jarvis`가 최초 부팅으로 동작(배너·강도 질문 등장). 정상.

## 하지 않는 것

- `.jarvis/baseline`·`.jarvis/args`를 삭제하지 않는다(재개니까 보존이 핵심).

## 참조
- 워치 본체: `.claude/skills/jarvis/SKILL.md`
- 일시정지: `.claude/skills/jarvis-pause/SKILL.md`
- 완전 종료: `.claude/skills/jarvis-stop/SKILL.md`
