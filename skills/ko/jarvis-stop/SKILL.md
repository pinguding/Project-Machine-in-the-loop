---
name: jarvis-stop
description: jarvis 워치를 완전히 종료하고 초기화한다. wake 루프 정지에 더해 .jarvis/baseline·args·paused 상태 파일을 모두 삭제한다. 다음 /jarvis는 최초 부팅(배너·강도 질문)부터 시작한다. "jarvis 그만", "워치 중지", "jarvis stop", "워치 완전 종료" 요청 시 사용.
---

# jarvis-stop

`jarvis` 워치를 **완전히 종료**한다. wake 루프를 멈추는 것에 더해, `.jarvis/`의 모든 제어 상태 파일(`baseline`·`args`·`paused`)을 지워 **초기 상태로 되돌린다.** 다음에 `/jarvis`를 부르면 최초 부팅처럼(시작 배너 + 강도 질문) 새로 시작한다.

> 잠깐만 멈췄다가 같은 설정으로 이어가려면 `/jarvis-stop`이 아니라 `/jarvis-pause`을 쓴다(상태 보존). `/jarvis-stop`은 **누적 변경 추적·저장된 강도까지 전부 버린다.**

## 동작 원리

jarvis 루프는 `ScheduleWakeup` 예약이 self-paced로 다음 tick을 부르는 구조다. `/jarvis-stop`은 **재예약을 하지 않고**, 루프 상태 파일을 삭제한다. 이미 예약된 wake가 한 번 더 발화하더라도 baseline이 없으면 최초 부팅 tick으로 취급되거나, paused가 없으니 그냥 새 tick을 돌 뿐 — 깔끔한 종료를 위해 상태를 비워 둔다.

## 절차

1. **상태 파일 일괄 삭제**:

   ```bash
   rm -f .jarvis/baseline .jarvis/args .jarvis/paused
   ```

   - `.jarvis/` 디렉토리 자체는 남겨도 무방하다(다른 캐시가 있을 수 있음). 비어 있어도 굳이 지우지 않는다.

2. **재예약 금지**: `ScheduleWakeup`을 **호출하지 않는다.** 예약이 없으면 루프는 자연히 멈춘다.

3. **보고** (한 줄): `🛑 Jarvis 워치 종료 + 상태 초기화. 다시 켜려면 /jarvis (배너·강도 질문부터 새로 시작).`

## 자연어 트리거

"jarvis 그만", "워치 중지", "stop loop", "워치 완전 종료" 같은 종료 의사도 이 스킬과 동일하게 처리한다(완전 초기화). 단순 일시정지를 원하는 뉘앙스("잠깐 멈춰", "이따 다시")면 `/jarvis-pause`을 제안한다.

## 하지 않는 것

- `ScheduleWakeup`을 호출하지 않는다.
- 사용자 워킹 트리의 코드/변경은 건드리지 않는다 — 지우는 건 `.jarvis/` 제어 파일뿐이다.

## 참조
- 워치 본체: `.claude/skills/jarvis/SKILL.md` ("제어 상태 파일" 표)
- 일시정지(상태 보존): `.claude/skills/jarvis-pause/SKILL.md`
- 재개: `.claude/skills/jarvis-resume/SKILL.md`
