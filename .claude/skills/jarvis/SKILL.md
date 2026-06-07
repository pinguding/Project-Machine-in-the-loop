---
name: jarvis
description: git 변경량을 self-paced로 폴링하다 임계값을 넘으면 jarvis-once 단발 리뷰를 자동 실행하는 워치 루프. args(key=value)로 강도 프리셋(strength)·임계값·간격·경로를 설정한다. args 없이 부르면 최초 1회 강도를 물어본다. 첫 로드 직후엔 잠깐 빠르게 폴링한다(warmup). "jarvis", "변경 감지 리뷰 루프", "jarvis 워치" 요청 시 사용.
---

# jarvis

사람이 직접 코드를 짜는 동안 곁에서 git 변경량을 싸게 폴링하다가, 의미 있는 분량이 쌓이면(임계값 초과) `jarvis-once`(단발 navigator) 스킬을 자동으로 한 번 돌려주는 self-paced 워치 루프다.

- **폴링은 토큰을 거의 쓰지 않는다** (`git diff --shortstat` 한 번). 비싼 `jarvis-once` 풀 리뷰는 임계값을 넘었을 때만 실행한다.
- **이벤트 기반이 아니다.** 사람 손 편집을 실시간으로 깨우는 OS 이벤트는 없으므로 주기적 wake로 확인한다. 대신 확인 자체를 극도로 싸게 유지한다.
- **`jarvis-once`는 코드를 직접 고치지 않는다** (리뷰/제안/다음 스텝만). 사람이 "이거 고쳐줘"라고 하면 그 턴은 일반 개발 모드로 전환한다.

> **이름 정리:** `jarvis`(이 스킬) = *지속 워치 루프*(진입점). `jarvis-once` = 트리거 시 *1회만 실행되는 단발 navigator*. 워치가 깨우면 `jarvis-once`를 호출한다.

## 실행 — 단독 호출로 자기 반복

이 스킬은 `/loop` 래퍼 없이 **`/jarvis` 단독 호출만으로 반복**된다. 반복의 엔진은 `/loop` 명령이 아니라 절차 4의 `ScheduleWakeup`이다.

- **시작**: 사용자가 `/jarvis [args]`를 한 번 호출한다. → 이번 tick을 수행하고, 마지막에 반드시 `ScheduleWakeup`으로 다음 실행을 예약한다(prompt에 현재 args echo). 이 예약이 곧 다음 tick의 진입점이다.
- **지속**: 예약된 wake가 발화하면 `/jarvis [args]`가 다시 실행되고, 또 다음 wake를 예약한다. 이렇게 사용자가 추가 입력 없이도 루프가 유지된다.
- **불변 규칙**: 종료 의사(아래 "중지")가 없는 한, **모든 tick은 끝에서 반드시 `ScheduleWakeup`을 호출한다.** 이 호출을 빠뜨리면 루프가 죽는다 — `/loop`이 없으므로 이걸 대신 살려줄 외부 하네스가 없다.
- 사용자가 굳이 `/loop /jarvis`로 불러도 동작은 동일하다(중복 예약하지 않도록 tick당 `ScheduleWakeup`은 1회만).

## 인자 (args, key=value)

| key | 의미 | 기본값 |
|-----|------|--------|
| `strength` | **강도 프리셋.** 아래 노브들을 한 번에 묶어 세팅한다(`low`/`medium`/`high`). 개별 노브를 같이 주면 그 항목만 덮어쓴다. 아래 "강도 프리셋" 참조. | `medium` |
| `threshold` | 직전 리뷰 이후 누적 변경 **라인 수** 임계값 | `50` |
| `files` | 변경 **파일 수** 임계값 (라인과 OR 조건) | `2` |
| `active` | 직전 wake에서 `jarvis-once`를 실행했거나 변경이 활발할 때의 다음 wake 간격 | `4m` |
| `idle` | 임계값 미달(잠잠)일 때의 다음 wake 간격 | `25m` |
| `debounce` | **대화가 멎었다고 볼 정지 시간.** 리뷰할 조건이 됐어도 사람이 대화 중이면 실행을 미루고 이 간격으로 짧게 재예약한다. 사람이 한 마디 할 때마다 타이머가 리셋된다. | `90s` |
| `warmup` | **첫 로드 빠른 폴링 tick 수.** 부팅 직후 이 횟수만큼은 임계값 미달이어도 `idle` 대신 `active` 간격으로 재확인한다(처음 켰을 때 반응을 빠르게). `0`이면 끔. | `3` |
| `paths` | 감시 대상 경로 한정 (생략 시 전체) | (전체) |
| `risk` | **위험 경로** glob — 여기에 매칭되는 파일은 분량과 무관하게(단 한 줄이라도 새로 바뀌면) `jarvis-once`를 깨운다. 쉼표로 여러 개. | (없음/off) |

> **커밋 경계 트리거는 args와 무관하게 항상 켜져 있다.** 새 커밋이 감지되면 임계값 미달이어도 그 커밋 변경에 대해 `jarvis-once`를 1회 실행한다. 착오가 코드로 봉인되기 직전/직후가 경고의 골든타임이기 때문이다. (manifesto: "사람의 착오에는 AI가 적극적으로 경고")

예시:

```
/jarvis                                              # args 없음 → 최초 1회 강도를 물어봄 (이후 medium 기본)
/jarvis strength=high                                 # 강하게 — 작은 변화도 자주 점검
/jarvis strength=low                                  # 약하게 — 큰 덩어리만 드물게
/jarvis strength=high threshold=40                    # 강 프리셋 + threshold만 40으로 덮어쓰기
/jarvis threshold=40                                  # 40라인 OR 2파일 (strength 미지정 → medium 베이스)
/jarvis threshold=80 files=3 idle=30m                 # 더 느슨하게
/jarvis paths=Projects/Musinsa active=3m              # 특정 경로만, 더 촘촘히
/jarvis risk=**/Payment*.swift,**/*Login*.swift       # 결제·로그인은 분량 무관 즉시 경고
```

인자 파싱 규칙:
- `key=value` 형태만 인식한다. 인식 못 한 토큰은 무시하고 기본값을 쓴다.
- `strength`를 먼저 해석해 프리셋 노브 묶음을 깐 뒤, 나머지 개별 key=value를 그 위에 덮어쓴다(개별 노브 우선). `strength` 미지정 시 `medium`과 동일.
- `strength` 값은 별칭을 허용한다(아래 "강도 프리셋" 표). 인식 못 한 값이면 `medium`으로 폴백한다.
- 시간 간격은 `s`/`m`/`h` 접미사를 허용한다(`90s`, `4m`, `1h`). 숫자만 오면 분으로 간주한다.
- `active`/`idle`은 런타임에서 [60s, 3600s]로 클램프된다.
- `paths`/`risk`는 쉼표(`,`)로 여러 값을 구분한다. glob 패턴을 허용한다.

## 강도 프리셋 (strength)

`strength` 하나로 "얼마나 예민하게/자주 점검할지"를 묶어 조절한다. 각 프리셋은 아래 노브 묶음으로 전개되며, 같은 호출에 개별 노브(`threshold=` 등)가 있으면 **그 항목만** 프리셋 값을 덮어쓴다.

| `strength` | 별칭 | `threshold` | `files` | `active` | `idle` | `debounce` | 성격 |
|-----------|------|-------------|---------|----------|--------|------------|------|
| `low` | `약`, `약하게`, `느슨`, `relaxed`, `1` | `120` | `4` | `8m` | `40m` | `120s` | 큰 덩어리만, 드물게. 소음 최소·비용 최소 |
| `medium` | `중`, `보통`, `normal`, `2` | `50` | `2` | `4m` | `25m` | `90s` | 기본. 균형 |
| `high` | `강`, `강하게`, `촘촘`, `aggressive`, `3` | `25` | `1` | `3m` | `12m` | `60s` | 작은 변화도, 자주. 가장 예민 |

규칙:
- 프리셋은 위 5개 노브(`threshold`/`files`/`active`/`idle`/`debounce`)만 건드린다. `paths`/`risk`는 프리셋과 무관하게 별도로 지정한다.
- `strength=high`라도 `jarvis-once` 자체의 severity 문턱은 그대로다 — 강도는 *호출 빈도*를 높일 뿐 잔소리를 늘리지 않는다(비용 가이드 참조). 즉 안심하고 올려도 된다.
- 다음 wake 예약 시 echo하는 args에는 **전개된 개별 노브가 아니라 `strength=<값>`(+ 개별 덮어쓰기)을 그대로** 직렬화한다. 그래야 프리셋 의미가 보존된다.

## 마커 파일

직전 리뷰 시점의 기준선을 `.jarvis/baseline`에 저장한다. 워킹 트리에 있으므로 `.gitignore`에 `.jarvis/`를 등록해 커밋되지 않게 하고(클론마다 독립적인 로컬 상태로 동작), 디렉토리가 없으면 쓰기 전에 `mkdir -p .jarvis`로 생성한다.

> **`.git/`을 쓰지 않는 이유:** `.git/` 내부는 민감 경로라 쓰기마다 권한 승인을 받아야 해서 무인 루프에 부적합하다. `.jarvis/`는 일반 워킹 트리 경로라 권한 마찰이 없고, `.gitignore`로 비추적을 보장하면 "커밋 안 됨 + 로컬 전용"이라는 원래 이점을 그대로 유지한다.

형식(한 줄): `lines=<정수> files=<정수> risk=<정수> head=<커밋 SHA> deferred=<0|1> boot=<정수>`
파일이 없으면 `lines=0 files=0 risk=0 head= deferred=0 boot=0`으로 간주한다. (구버전 파일에 `boot`가 없으면 0으로 본다.)
- `lines` / `files`: 직전 리뷰 시점의 working tree 변경 라인/파일 수
- `risk`: 직전 리뷰 시점의 위험 경로(`risk` glob) 변경 라인 수 (risk 미설정 시 0)
- `head`: **직전 tick에서 관측한** `git rev-parse HEAD` 값. 커밋 경계 감지에 쓴다.
- `deferred`: 리뷰할 조건이 됐지만 대화 중이라 **미뤄둔 리뷰가 있는지**(debounce 대기). 1이면 대화가 멎는 순간 flush한다.
- `boot`: 남은 **웜업 tick 수.** 부팅 시 `warmup`으로 초기화되고 매 tick 1씩 줄어든다. `>0`이면 임계값 미달 tick도 `idle` 대신 `active` 간격으로 폴링한다(첫 로드 직후 빠른 반응).

### 제어 상태 파일 (`.jarvis/` 하위)

워치의 생애주기는 아래 3개 파일로 제어된다. 모두 `.jarvis/` 하위라 `.gitignore`로 비추적·로컬 전용이다.

| 파일 | 역할 | 생성/삭제 주체 |
|------|------|----------------|
| `.jarvis/baseline` | 위 형식의 워치 기준선. 루프 진행 상태의 핵심. | 매 tick 기록 / `/jarvis-stop`이 삭제 |
| `.jarvis/args` | 직전 tick의 유효 args 문자열(예: `strength=medium`). 매 tick 갱신. `/jarvis-resume`이 이 값으로 같은 설정으로 되살린다. 없으면 기본값(medium)으로 재개. | 매 tick 기록 / `/jarvis-stop`이 삭제 |
| `.jarvis/paused` | **일시정지 플래그.** 존재하면 깨어난 tick이 측정·리뷰·재예약을 전부 건너뛰고 즉시 종료한다(절차 0.4). baseline·args는 보존되므로 `/jarvis-resume`으로 이어서 재개 가능. | `/jarvis-pause`이 생성 / `/jarvis-resume`·`/jarvis-stop`이 삭제 |

> 동반 명령 스킬: **`/jarvis-pause`**(wake 루프만 정지, 상태 보존) · **`/jarvis-resume`**(루프 재개) · **`/jarvis-stop`**(루프 정지 + baseline/args/paused 전부 삭제, 완전 초기화). 상세는 각 스킬의 SKILL.md 참조.

## 컨벤션 문서 수집 (`jarvis-once` 호출 직전에만 수행)

`jarvis-once`를 실제로 부르기로 결정한 순간(절차 2a 또는 3 충족)에만 수행한다. 미달 tick에서는 토큰 낭비이므로 **하지 않는다.**

목적: `jarvis-once`가 "이 패키지·이 디렉토리 규칙"까지 알고 리뷰하게 한다. `CLAUDE.md`와 `.claude/rules/**`는 하네스가 자동 주입하므로 **중복 수집하지 않는다.** on-demand 문서만 모은다.

변경된 파일 목록을 먼저 얻는다:

```bash
git diff --name-only HEAD [-- paths]      # 게이트로 깨운 경우 (working tree)
git diff --name-only <base_head>..<cur_head>   # 커밋 경계로 깨운 경우
```

그 경로들을 기준으로 다음을 수집한다(존재하는 것만, **이미 컨텍스트에 있으면 재읽기 금지**):

1. **가장 가까운 `AGENTS.md`** — 각 변경 파일의 디렉토리에서 위로 올라가며 처음 만나는 `AGENTS.md`. (예: `Projects/Musinsa/**` 변경 → `Projects/Musinsa/AGENTS.md`)
2. **디렉토리 `README.md`** — 변경 파일이 위치한 디렉토리에 `README.md`가 있으면 그 파일.
3. **경로/종류별 `.claude/rules` 매핑** — 변경 파일 종류에 맞는 규칙 문서만 추려서(전부 말고) 참조:
   - `*Reactor.swift` → `ios/reactorkit-architecture.md`, `ios/state-exposure.md`
   - `*ViewController.swift` / `*View.swift` / `*Cell.swift` → `ios/ui-development.md`, `core/class-organization.md`
   - `*ServiceStub.swift` / `Tests/**` → `core/testing-guidelines.md`
   - `*.swift` 공통 → `core/swift-conventions.md` *(단 자동 주입돼 있으면 생략)*

중복·과수집을 피한다: 같은 `AGENTS.md`를 여러 변경 파일이 공유하면 한 번만 읽는다. 수집량이 과하면 변경 파일이 가장 많은 상위 디렉토리 1~2곳으로 한정한다.

수집한 내용을 `jarvis-once` 호출 시 "참고 컨벤션" 맥락으로 함께 전달한다.

## Jarvis 출력 마커 (필수)

`jarvis-once` 리뷰 결과를 사용자에게 전달할 때는, 그 내용이 **Jarvis가 자동 생성한 것**임을 보이도록 반드시 시작/끝에 아래 마커로 감싼다. 워치가 자동으로 내놓은 출력과 일반 대화를 구분하기 위함이다.

**시작 마커:**

```
╭─🤖 JARVIS ─────────────── (jarvis 자동 관찰)
```

**끝 마커:**

```
╰─🤖 JARVIS ─────────────── 키보드는 당신이 잡습니다 · 판단은 당신 몫
```

규칙:
- `jarvis-once`가 실제로 무언가 말할 때만(리뷰 내용이 있을 때) 감싼다. "특별히 걸리는 건 없어" 수준의 침묵·미달 한 줄 알림에는 마커를 붙이지 않는다.
- 마커 사이 본문은 `jarvis-once`가 생성한 내용 그대로 둔다. 워치(`jarvis`) 자신의 운영 메시지(예약·debounce 안내 등)는 마커 **밖**에 둔다.
- 끝 마커의 꼬리 문구는 저자성이 사람에게 있음을 상기시키는 고정 문구다.

## 시작 배너 (최초 tick 전용)

`/jarvis`가 **처음 가동되는 tick**에서만 `JARVIS` 아스키 로고 배너를 **1회** 출력한다. 판정 기준: `.jarvis/baseline` 파일이 **아직 없으면** 최초 부팅 tick이다(이후 tick엔 baseline이 생기므로 자동으로 재출력 안 됨). 예약 wake·이후 tick에서는 출력하지 않는다 — 반복은 노이즈다.

**항상 보이게 — 반드시 "어시스턴트 응답 본문"에 코드펜스로 직접 출력한다.**
`cat`으로만 내보내면 Claude Code UI가 긴 tool 출력을 접어버려(Ctrl+O 필요) 배너가 바로 안 보인다. 따라서:
1. `assets/jarvis-banner.txt`(이미 컨텍스트에 있으면 재읽기 불필요)를 읽어 내용을 확보하고,
2. 그 내용을 **응답 메시지 안의 삼중 백틱(```) 코드블록에 그대로 붙여** 출력한다. (tool 출력이 아니라 본문이라 항상 펼쳐져 보인다)

- 색: 본문 마크다운은 ANSI 색을 못 살리므로 **모노크롬**으로 나간다. 이 로고는 블록 글자(`█`)와 박스 모서리(`╗╝╚╔║═`)로 `JARVIS` 형태가 또렷이 드러난다. (굳이 컬러가 필요하면 `assets/jarvis-banner.ansi`를 **raw 터미널**에서 `cat` — 단 Claude Code UI에선 접힘.)
- 원본 아트: `assets/jarvis-banner.txt`. (`colorize.sh` → `.ansi`는 raw 터미널용 컬러 fallback으로만 유지)
- 배너는 워치 운영 메시지이므로 "Jarvis 출력 마커"(╭─🤖) **밖**에 둔다. 배너 아래 캡션 한 줄을 덧붙인다:
  `J · A · R · V · I · S  —  watch online · 키보드는 당신이 잡습니다`

## 매 실행(wake) 절차

> 이 스킬은 매 wake마다 아래를 처음부터 끝까지 수행한다.

### 0. 사람 우선 + 대화 활성도 판정 (debounce)
**`active_chat` 판정:** 직전 tick(직전 `ScheduleWakeup` 발화) 이후 사람이 보낸 메시지가 있는가? transcript 끝부분으로 판정한다.
- 사람의 의논/구현 메시지가 있었으면 → `active_chat = true` (대화 중)
- 이번 tick이 순수 예약 발화뿐이면 → `active_chat = false` (조용)

`active_chat == true`이고 사람이 무언가 요청 중이면, **그 요청(질문 답변·코드 작성·명령 실행)에 먼저 집중한다.** 워치 출력으로 대화를 끊지 않는다. 리뷰는 미루고, 절차 3·2a의 debounce 분기가 처리한다(절차 4에서 `debounce` 간격으로 재예약).

이 `active_chat` 값은 절차 2a·3의 "말해도 되는가" 판단에 쓰인다.

### 0.4. 일시정지 플래그 체크 (최우선 — 다른 모든 절차에 우선)
`.jarvis/paused` 파일이 존재하면 이 워치는 **일시정지** 상태다. 이번 tick은 측정·게이트·리뷰·기준선 기록을 **전부 건너뛰고**, 절차 4(`ScheduleWakeup`)를 **수행하지 않는다.** 예약이 사라지므로 루프가 자연히 멈춘다.
- `.jarvis/baseline`·`.jarvis/args`는 **지우지 않는다**(재개용 상태 보존).
- 한 줄로만 알린다: `⏸ Jarvis 일시정지 중 — /jarvis-resume으로 재개`. (배너·리뷰·운영 메시지 모두 생략)
- 이 체크는 0.5(배너)·0.6(강도)보다 먼저 수행한다 — 일시정지 중엔 아무것도 출력하지 않는다.

### 0.5. 시작 배너 (최초 부팅 1회)
`.jarvis/baseline` 파일이 **없으면** 이번이 최초 가동 tick이다 → "시작 배너" 섹션 규칙대로 `JARVIS` 아스키 로고를 **응답 본문 코드펜스에** 1회 출력한다(마커 밖, 캡션 포함, 항상 보임). 파일이 이미 있으면 건너뛴다. 배너 출력 후에도 절차 1~4는 정상 진행한다.

### 0.6. 강도 선택 (최초 부팅 + args 없을 때만 1회)
**조건:** 이번이 최초 가동 tick(`0.5`에서 baseline 없음 판정)이고 **인식된 args가 하나도 없을 때만** 수행한다.
- `AskUserQuestion`으로 강도를 1회 묻는다. 선택지는 `강하게(high)` / `보통(medium)` / `약하게(low)` 3개 + 각 프리셋의 노브 요약을 description에 적는다. (사용자는 "Other"로 직접 값을 줄 수도 있다.)
- 사용자가 고른 값을 이번 tick의 `strength`로 확정하고, 절차 4의 wake 예약 prompt에 `strength=<선택값>`을 echo한다. 이후 wake부터는 args가 비어있지 않으므로 다시 묻지 않는다.
- **예약 wake(자동 발화) tick에서는 절대 묻지 않는다** — args(`strength=` 포함)가 항상 echo되므로 이 분기에 들어오지 않는다. 사용자가 자리를 비운 사이 질문으로 루프가 막히는 일을 방지한다.
- args가 하나라도 있으면(예: `/jarvis strength=high`, `/jarvis threshold=40`) 질문 없이 그 값을 그대로 쓴다.

> 이 질문은 "처음 켤 때 한 번"만이다. 강도를 나중에 바꾸려면 `/jarvis strength=<값>`으로 다시 부르면 된다(진행 중인 예약을 덮어쓴다).

### 1. 측정 (저비용)
`paths`가 있으면 `-- <paths>`를 붙여서 working tree 변경량을 잰다:

```bash
git diff --shortstat HEAD -- [paths]
```

출력에서 `files changed`, `insertions(+)`, `deletions(-)`를 파싱한다.
- `cur_lines = insertions + deletions`
- `cur_files = files changed`
- 출력이 비어 있으면 둘 다 0.

`risk`가 설정돼 있으면 위험 경로만 따로 잰다:

```bash
git diff --shortstat HEAD -- <risk globs>
```
→ `risk_lines = insertions + deletions` (위험 경로 기준). risk 미설정 시 0.

현재 커밋도 확인한다:

```bash
git rev-parse HEAD
```
→ `cur_head`.

> 측정은 staged+unstaged 모두 포함하는 working tree 기준(`HEAD` 대비)이다.

### 2. 경계 판단 (커밋·되돌림 자동 보정)
`.jarvis/baseline`에서 `base_lines`, `base_files`, `base_risk`, `base_head`를 읽는다.

**(a) 커밋 경계 — 강제 관찰 (항상 켜짐):**
`base_head`가 비어있지 않고 `cur_head != base_head`이면, 직전 tick 이후 **새 커밋이 생겼다**(commit/merge). 분량과 무관하게 `jarvis-once`로 1회 점검한다.
- **단, `active_chat`이면(대화 중) 이 커밋 점검도 미룬다:** `deferred = 1`로 두고 **`base_head`를 갱신하지 않은 채** 절차 4에서 `debounce` 간격으로 재예약한다. 조용해지면 다음 tick에서 이 분기로 다시 들어와 실행한다. (커밋 점검이 유실되지 않도록 head를 일부러 안 옮긴다)
- 조용하면(`active_chat == false`) 바로 실행:
  - 보여줄 diff: `base_head`가 `cur_head`의 조상이면 `git diff <base_head>..<cur_head>`, 아니면(rebase/checkout/force 등) `git show <cur_head>`
  - 먼저 "컨벤션 문서 수집"을 수행해 함께 넘긴다.
  - `jarvis-once`에 "막 커밋된 변경이다. 봉인 직전 마지막 점검 관점으로 착오·누락을 봐달라"는 맥락을 전달한다.
  - 리뷰 결과를 **"Jarvis 출력 마커"로 감싸** 전달한다.
  - 실행 후 절차 3(게이트)은 **건너뛴다.** 기준선을 현재값으로 갱신하고 `deferred=0`으로 절차 4로 간다.
- 단, 사용자가 종료를 요청한 상태면 실행하지 않는다.

**(b) 되돌림(discard) 감지:**
`cur_head == base_head`인데 `cur_lines < base_lines`이면, 사용자가 변경을 되돌린 것이다. 기준선을 현재값으로 리셋하고 `jarvis-once`는 실행하지 않는다. (절차 4로)

**(c) 그 외 — 증가분 계산:**
- `delta_lines = cur_lines - base_lines`
- `delta_files = cur_files` (파일 수는 working tree 절대값으로 판단)
- `delta_risk  = risk_lines - base_risk` (risk 미설정 시 0)

### 3. 게이트 + debounce 판단

**게이트 충족 여부** — 다음 중 하나라도 충족하면 `gate_met = true`:
- `delta_lines >= threshold`
- `delta_files >= files`
- `risk` 설정 시 `delta_risk >= 1` — 위험 경로는 분량 무관. 단 한 줄이라도 새로 바뀌면 경고. (tenet 7: 위험에 반응)

**리뷰 필요 여부**: `should_review = gate_met OR (base_deferred == 1)`
→ 이전에 미뤄둔 리뷰가 있으면 게이트가 다시 충족되지 않아도 리뷰 대상이다(미뤄둔 변경은 사라지지 않는다).

**말해도 되는가**: `may_speak_now = (active_chat == false)` — 대화가 멎은 상태.

분기:

- **should_review && may_speak_now → 실행 (flush):**
  1. "컨벤션 문서 수집"을 수행한다.
  2. `Skill('jarvis-once')`를 호출해 현재 변경분(working tree diff)을 리뷰받는다. 수집한 참고 컨벤션 + "직전 리뷰 이후 새로 쌓인 변경 위주로 봐달라" 맥락을 함께 전달한다. 위험 경로/미뤄둔 리뷰 때문이면 그 사실을 명시한다.
  3. 리뷰 결과를 **"Jarvis 출력 마커"로 감싸** 사용자에게 간결히 전달한다.
  4. `deferred = 0`으로 클리어.

- **should_review && !may_speak_now → 미룸 (debounce):**
  - `jarvis-once`를 실행하지 않는다. `deferred = 1`로 표시.
  - 워치 운영 메시지를 마커 **밖**에 한 줄로 남긴다(예: "변경 감지 — 대화 중이라 보류, 멎으면 리뷰할게").
  - 절차 4에서 `debounce` 간격으로 짧게 재예약한다.

- **그 외 (should_review == false):** 아무 것도 출력하지 않거나 한 줄만("변경 +N라인 — 임계값 미달, 대기").

**기준선 기록 규칙 (절차 끝에서 항상 적용):**
- `head`: 매 tick 끝에 `cur_head`로 기록한다. **단, 커밋 경계(2a)를 debounce로 미룬 경우는 예외** — 다음 조용한 tick에서 다시 감지되도록 `head`를 갱신하지 않는다.
- `lines` / `files` / `risk`: **`jarvis-once`를 실행(flush)했거나 되돌림 리셋(2b)한 경우에만** 현재값(`cur_lines`/`cur_files`/`risk_lines`)으로 갱신한다. 미룸·미충족 tick에서는 기존 값을 유지해 변경이 계속 누적되게 둔다.
- `deferred`: 위 분기 결과(0/1)를 기록한다.
- `boot`: `boot_now`에서 1 줄여 기록한다(최소 0). 즉 부팅 후 `warmup` tick 동안만 웜업 폴링이 유지되고, 그 뒤 자동으로 `idle`로 내려간다. `warmup=0`이면 처음부터 웜업 없음.

### 4. 다음 wake 예약 (루프 유지의 핵심)
`ScheduleWakeup`을 호출해 다음 실행을 예약한다.

- **웜업 판정:** `boot_now`를 정한다 — 최초 부팅 tick(0.5에서 baseline 없음으로 판정)이면 `warmup` 값, 아니면 baseline의 `boot` 값(없으면 0).
- 간격 결정:
  - 이번 tick에서 리뷰를 **미뤘으면**(`deferred`를 1로 세팅) → `debounce` (짧게, 곧 다시 확인)
  - 이번 tick에서 `jarvis-once`를 **실행(flush)했으면** → `active`
  - 미충족이지만 **웜업 중**(`boot_now > 0`) → `active` (첫 로드 직후엔 idle 대신 빠르게 재확인)
  - 그 외(미충족 · 웜업 종료) → `idle`
- **prompt에는 이번에 받은 args를 그대로 echo 한다.** 그래야 다음 wake에서도 설정이 유지된다. `strength`를 쓴 경우 **전개된 개별 노브가 아니라 `strength=<값>`(+ 개별 덮어쓰기)** 형태로 직렬화한다(강도 의미 보존). 예:

  ```
  /jarvis strength=high paths=Projects/Musinsa risk=**/Payment*.swift
  /jarvis strength=high threshold=40                      # 프리셋 + 개별 덮어쓰기도 그대로 echo
  /jarvis threshold=50 files=2 active=4m idle=25m debounce=90s   # strength 미사용 시는 개별 노브로 echo
  ```

  ⚠️ 이 echo를 빠뜨리면 두 번째 wake부터 모든 설정이 기본값으로 돌아간다. 반드시 현재 유효 args 전체(`strength` 또는 개별 노브 + `paths`·`risk`)를 직렬화해 넘긴다.
- **resume용 args 저장:** wake 예약과 함께, prompt에 echo한 것과 **동일한 args 문자열**을 `.jarvis/args`에 1줄로 기록한다(`/jarvis ` 접두어 없이 args만). `/jarvis-resume`이 이 값을 읽어 같은 설정으로 루프를 되살린다.
- `reason`에는 무엇을 기다리는지 구체적으로 적는다(예: "변경 누적 폴링, 다음 4분 뒤 확인").

## 중지 / 일시정지 / 재개

세 동작은 별도 명령 스킬로 분리돼 있다. 자연어("jarvis 그만" 등)로도 트리거되지만, 명시적 호출을 권장한다.

| 명령 | 동작 | 상태 파일 | 재개 |
|------|------|-----------|------|
| **`/jarvis-pause`** | wake 루프만 정지(측정·리뷰는 안 함). 진행 상태는 보존. | `.jarvis/paused` 생성, baseline·args **유지** | `/jarvis-resume`으로 같은 설정 이어서 재개 |
| **`/jarvis-resume`** | 일시정지 해제 + 루프 재시작. `.jarvis/args`의 설정을 복원. | `.jarvis/paused` 삭제 | — |
| **`/jarvis-stop`** | 루프 정지 + **완전 초기화**. 다음엔 최초 부팅처럼 시작(배너·강도 질문 재등장). | `.jarvis/baseline`·`.jarvis/args`·`.jarvis/paused` 전부 삭제 | `/jarvis`로 새로 시작 |

작동 원리:
- **일시정지(가벼운 양보)**: 사용자가 그냥 다른 메시지를 보내면 그 턴은 절차 0에 따라 의논/구현에 양보한다(워치 자체는 살아 있음). 이건 명령 없이 일어나는 암묵적 양보다.
- **`/jarvis-pause`**: `.jarvis/paused`를 만들어 둔다. 이미 예약된 wake가 한 번 더 발화하더라도 절차 0.4에서 즉시 빠져나가 **재예약하지 않으므로** 루프가 멈춘다. baseline·args는 그대로라 손실 없이 재개 가능.
- **`/jarvis-stop`**: `.jarvis/` 상태 파일을 모두 지우고 재예약하지 않는다. 예약이 없으면 루프는 자연히 멈춘다. ("jarvis 그만", "워치 중지", "stop loop"도 동일하게 처리)
- **`/jarvis-resume`**: `.jarvis/paused`를 지우고 `Skill('jarvis')`를 저장된 args로 재호출해 첫 tick을 돌린다. 그 tick이 절차 4에서 다시 `ScheduleWakeup`을 걸어 루프가 이어진다.

## 비용 가이드 (사용자 안내용)

- wake 간격이 5분 미만이면 prompt 캐시(TTL 5분)가 살아 폴링 턴이 거의 공짜다. 그래서 `active` 기본값은 4분이다.
- 잠잠할 때는 `idle`을 길게(기본 25분) 두어 캐시 미스 누적 비용을 줄인다.
- 실제 토큰의 대부분은 "`jarvis-once`가 도는 순간"(임계값 초과·위험 경로·커밋 경계)에 쓰인다. 임계값을 올리면 비용이 준다.
- 임계값을 **낮게** 잡아도 소음은 늘지 않는다. `jarvis-once`는 자체 severity 문턱 아래선 스스로 조용히 있기 때문이다. 낮은 임계값은 *호출 비용*만 늘릴 뿐 잔소리를 늘리지 않는다 — 위험 민감도를 높이고 싶으면 안심하고 낮춰도 된다.
- 커밋 경계 트리거는 커밋당 1회뿐이라 비용이 예측 가능하고, "착오 봉인 직전" 단 한 번의 점검이라 비용 대비 가치가 가장 높은 실행이다.

## 의존성 주의

이 스킬은 `jarvis-once`(단발 navigator) 스킬을 호출한다. 팀에 공유하려면 `jarvis-once`도 함께 접근 가능해야 한다(레포 `.claude/skills/jarvis-once/` 또는 공통 레포). 개인 글로벌(`~/.claude/skills/jarvis-once/`)에만 있으면 다른 팀원 환경에서는 호출이 실패할 수 있다.
