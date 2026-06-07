---
name: jarvis-pause
description: jarvis 워치의 wake 루프만 일시정지한다. baseline·args 진행 상태는 보존하므로 /jarvis-resume으로 같은 설정에서 이어서 재개할 수 있다. "jarvis 일시정지", "워치 잠깐 멈춰", "jarvis pause" 요청 시 사용.
---

# jarvis-pause

`jarvis` 워치의 **wake 루프만** 멈춘다. 측정·리뷰·재예약을 더 이상 하지 않되, **진행 상태(baseline·args)는 보존**한다. 나중에 `/jarvis-resume`을 부르면 멈춘 지점의 설정 그대로 이어서 재개된다.

> 완전히 끄고 초기화하려면 `/jarvis-stop`을, 다시 켜려면 `/jarvis-resume`을 쓴다.

## 동작 원리

jarvis 루프는 별도 데몬 없이 `ScheduleWakeup` 예약이 스스로 다음 tick을 부르는 self-paced 구조다. 따라서 "정지"는 **다음 예약을 걸지 않게** 만드는 것이다.

`/jarvis-pause`은 `.jarvis/paused` 플래그 파일을 만든다. 이미 예약돼 있던 wake가 한 번 더 발화하더라도, jarvis 절차 0.4(최우선 일시정지 체크)에서 즉시 빠져나가 **재예약하지 않으므로** 루프가 자연히 멈춘다. `.jarvis/baseline`·`.jarvis/args`는 건드리지 않아 손실 없이 재개할 수 있다.

## 절차

1. **디렉토리 보장**: `.jarvis/`가 없으면 만든다.

   ```bash
   mkdir -p .jarvis
   ```

2. **일시정지 플래그 생성**: 사람이 읽을 수 있게 한 줄 메모를 남긴다(내용은 자유, 존재 자체가 플래그).

   ```bash
   printf 'paused by /jarvis-pause\n' > .jarvis/paused
   ```

3. **상태 확인 후 보고** (한 줄):
   - `.jarvis/baseline`이 있으면 → `⏸ Jarvis 워치 일시정지. 진행 상태 보존됨 — /jarvis-resume으로 이어서 재개.`
   - `.jarvis/baseline`이 없으면(워치가 실제로 돈 적 없음) → `⏸ 활성 워치는 없었지만 일시정지 플래그를 걸어둠. 예약된 wake가 있어도 재시작하지 않음. /jarvis-resume으로 시작 가능.`

## 하지 않는 것

- `ScheduleWakeup`을 호출하지 않는다(루프를 살리지 않는다).
- `.jarvis/baseline`·`.jarvis/args`를 삭제하지 않는다(그건 `/jarvis-stop`의 일).
- 배너·리뷰·운영 메시지를 출력하지 않는다 — 한 줄 보고로 끝낸다.

## 참조
- 워치 본체: `.claude/skills/jarvis/SKILL.md` (절차 0.4 일시정지 체크, "제어 상태 파일" 표)
- 재개: `.claude/skills/jarvis-resume/SKILL.md`
- 완전 종료: `.claude/skills/jarvis-stop/SKILL.md`
