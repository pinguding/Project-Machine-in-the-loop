---
name: jarvis
description: A watch loop that polls git change volume in a self-paced manner and automatically runs the jarvis-once one-shot review when new change has accrued since the last review, a risk path changed, or a new commit appeared. There is no fixed line/file threshold. Configure strength preset, polling intervals, paths, and risk paths via args (key=value). When called without args, it asks for strength once on first run. Right after first load it polls quickly for a short while (warmup). Use for "jarvis", "change-detection review loop", "jarvis watch" requests.
---

# jarvis

A self-paced watch loop that cheaply polls git change volume while a human writes code directly, and once **new change has accrued since the last review** (no volume threshold), automatically runs the `jarvis-once` (one-shot navigator) skill once.

- **Polling uses almost no tokens** (one `git diff --shortstat`). The expensive `jarvis-once` full review runs only when new change has accrued since the last review, a risk path changed, or a new commit appeared.
- **It is not event-driven.** There is no OS event that wakes it in real time on a human's hand edits, so it checks via periodic wakes. Instead, it keeps the check itself extremely cheap.
- **`jarvis-once` does not fix code directly** (review/suggest/next steps only). If the human says "fix this," that turn switches to normal development mode.

> **Naming:** `jarvis` (this skill) = *the persistent watch loop* (entry point). `jarvis-once` = the *one-shot navigator that runs exactly once* when triggered. When the watch wakes, it calls `jarvis-once`.

## Execution — self-repeating via a single call

This skill **repeats with just a single `/jarvis` call**, without a `/loop` wrapper. The engine of repetition is not the `/loop` command but the `ScheduleWakeup` in procedure 4.

- **Start**: The user calls `/jarvis [args]` once. → Perform this tick and, at the end, always schedule the next run with `ScheduleWakeup` (echoing the current args in the prompt). This schedule is the entry point of the next tick.
- **Persist**: When the scheduled wake fires, `/jarvis [args]` runs again and schedules yet another wake. This way the loop is maintained without any further user input.
- **Invariant**: Unless there is an intent to terminate (see "Stop" below), **every tick must call `ScheduleWakeup` at its end.** Omitting this call kills the loop — since there is no `/loop`, there is no external harness to revive it.
- Even if the user does call it as `/loop /jarvis`, the behavior is identical (to avoid duplicate scheduling, call `ScheduleWakeup` only once per tick).

## Arguments (args, key=value)

| key | meaning | default |
|-----|------|--------|
| `strength` | **Strength preset.** Sets the polling-interval knobs below as a bundle in one go (`low`/`medium`/`high`). If individual knobs are given alongside, only those items are overridden. See "Strength preset" below. | `medium` |
| `active` | Next wake interval when `jarvis-once` ran on the previous wake or the working tree has changes | `4m` |
| `idle` | Next wake interval when there is no change (working tree clean) | `25m` |
| `debounce` | **Quiet time after which the conversation is considered to have stopped.** Even if conditions to review are met, if the human is mid-conversation, defer execution and reschedule briefly at this interval. Every time the human says something, the timer resets. | `90s` |
| `warmup` | **Number of fast-polling ticks on first load.** Right after boot, for this many ticks, recheck at the `active` interval instead of `idle` even when there is no change (fast response when first turned on). `0` turns it off. | `3` |
| `paths` | Limit the watch target to these paths (whole tree if omitted) | (whole tree) |
| `risk` | **Risk path** glob — files matching this wake `jarvis-once` regardless of volume (even a single newly changed line). Comma-separate multiple. | (none/off) |
| `focus` | **Focus area directory.** The `.md` collected here is viewed as a priority lens during review (see "Convention document collection" item 4). | `.claude/jarvis/focus/` |
| `mirror` | **Mirror (gray-zone visualization).** If a substantial part of the cumulative changes is code *generated* in this session, point it out with a one-line memo on "whether you grasped it yourself" (non-enforcing). Turn off with `off`. See procedure 3.5 below. | `on` |

> **The commit-boundary trigger is always on, independent of args.** When a new commit is detected, `jarvis-once` runs once on that commit's changes regardless of accrued volume. This is because right before/after a mistake is sealed into code is the golden time for a warning. (manifesto: "AI actively warns about human mistakes")

Examples:

```
/jarvis                                              # no args → asks for strength once (medium default thereafter)
/jarvis strength=high                                 # strong — poll tightly (catch new change fast)
/jarvis strength=low                                  # weak — poll rarely
/jarvis strength=high idle=30m                        # high preset + override only idle to 30m
/jarvis paths=src/billing active=3m                   # specific path only, more frequent
/jarvis risk=**/*payment*,**/*auth*                   # payment/auth warned immediately on a single changed line
```

Argument parsing rules:
- Only `key=value` form is recognized. Unrecognized tokens are ignored and defaults are used.
- Interpret `strength` first to lay down the preset knob bundle, then overlay the remaining individual key=value on top (individual knobs win). If `strength` is unspecified, equivalent to `medium`.
- The `strength` value allows aliases (see "Strength preset" table). If the value is unrecognized, fall back to `medium`.
- Time intervals allow `s`/`m`/`h` suffixes (`90s`, `4m`, `1h`). A bare number is treated as minutes.
- `active`/`idle` are clamped to [60s, 3600s] at runtime.
- `paths`/`risk` separate multiple values with commas (`,`). Glob patterns are allowed.

## Strength preset (strength)

Use a single `strength` to bundle "how tightly to poll." Each preset expands into the knob bundle below, and if individual knobs (`active=`, etc.) are present in the same call, **only those items** override the preset values. (Since there is no line/file threshold, the preset changes *polling frequency*, not *volume sensitivity*.)

| `strength` | aliases | `active` | `idle` | `debounce` | character |
|-----------|------|----------|--------|------------|------|
| `low` | `약`, `약하게`, `느슨`, `relaxed`, `1` | `8m` | `40m` | `120s` | Poll rarely. Minimal noise, minimal cost |
| `medium` | `중`, `보통`, `normal`, `2` | `4m` | `25m` | `90s` | Default. Balanced |
| `high` | `강`, `강하게`, `촘촘`, `aggressive`, `3` | `3m` | `12m` | `60s` | Poll tightly. Catches new change/commits fastest |

Rules:
- The preset touches only the 3 knobs above (`active`/`idle`/`debounce`). `paths`/`risk` are specified separately, independent of the preset.
- Even with `strength=high`, the severity threshold of `jarvis-once` itself is unchanged — strength only raises the *polling frequency* (how fast new change is caught), not the nagging (see cost guide). So you can raise it with peace of mind.
- When scheduling the next wake, serialize the echoed args as **`strength=<value>` (+ individual overrides) as-is, not the expanded individual knobs.** That way the preset's meaning is preserved.

## Marker files

The baseline at the time of the last review is stored in `.jarvis/baseline`. Since it lives in the working tree, register `.jarvis/` in `.gitignore` so it is not committed (it operates as independent local state per clone), and if the directory does not exist, create it with `mkdir -p .jarvis` before writing.

> **Why not use `.git/`:** The inside of `.git/` is a sensitive path, requiring permission approval on every write, which is unsuitable for an unattended loop. `.jarvis/` is an ordinary working-tree path with no permission friction, and guaranteeing it is untracked via `.gitignore` preserves the original benefit of "not committed + local only" as-is.

Format (one line): `lines=<int> risk=<int> head=<commit SHA> deferred=<0|1> boot=<int> mirrored=<0|1>`
If the file does not exist, treat it as `lines=0 risk=0 head= deferred=0 boot=0 mirrored=0`. (If an old-version file lacks `boot`/`mirrored`, treat them as 0; if a leftover `files` field is present, ignore it.)
- `lines`: working-tree changed line count at the time of the last review. This is the baseline for deciding "has new change accrued since the last review."
- `risk`: changed line count on risk paths (`risk` glob) at the time of the last review (0 if risk unset)
- `head`: the `git rev-parse HEAD` value **observed on the previous tick.** Used for commit-boundary detection.
- `deferred`: whether there is a **deferred review** that met conditions to review but was held off because of an ongoing conversation (debounce wait). If 1, flush the moment the conversation stops.
- `boot`: remaining **warmup tick count.** Initialized to `warmup` at boot and decremented by 1 each tick. If `>0`, even no-change ticks poll at the `active` interval instead of `idle` (fast response right after first load).
- `mirrored`: **mirror cooldown flag.** Set to 1 after showing the mirror (procedure 3.5) to prevent repeated firing every tick. Released to 0 when human-typed changes again dominate or a review is flushed.

### Control state files (under `.jarvis/`)

The watch's lifecycle is controlled by the 3 files below. All are under `.jarvis/`, so they are untracked and local-only via `.gitignore`.

| file | role | created/deleted by |
|------|------|----------------|
| `.jarvis/baseline` | The watch baseline in the format above. The core of loop progress state. | written every tick / deleted by `/jarvis-stop` |
| `.jarvis/args` | The effective args string of the previous tick (e.g., `strength=medium`). Updated every tick. `/jarvis-resume` revives with the same settings using this value. Resumes with the default (medium) if absent. | written every tick / deleted by `/jarvis-stop` |
| `.jarvis/paused` | **Pause flag.** If it exists, a woken tick skips measurement/review/rescheduling entirely and exits immediately (procedure 0.4). baseline/args are preserved, so it can be resumed afterward with `/jarvis-resume`. | created by `/jarvis-pause` / deleted by `/jarvis-resume`·`/jarvis-stop` |

> Companion command skills: **`/jarvis-pause`** (stop only the wake loop, preserve state) · **`/jarvis-resume`** (resume the loop) · **`/jarvis-stop`** (stop the loop + delete baseline/args/paused entirely, full reset). See each skill's SKILL.md for details.

## Convention document collection (performed only right before calling `jarvis-once`)

Performed only the moment it is decided to actually call `jarvis-once` (procedure 2a or 3 satisfied). On ticks with no review this is a waste of tokens, so **do not do it.**

Purpose: let `jarvis-once` review with knowledge of "this package's, this directory's rules." `CLAUDE.md` and `.claude/rules/**` are auto-injected by the harness, so **do not collect them redundantly.** Gather only on-demand documents.

First obtain the list of changed files:

```bash
git diff --name-only HEAD [-- paths]      # when woken by the gate (working tree)
git diff --name-only <base_head>..<cur_head>   # when woken by the commit boundary
```

Based on those paths, collect the following (only what exists, and **do not re-read if already in context**):

1. **Nearest `AGENTS.md`** — going up from each changed file's directory, the first `AGENTS.md` encountered. (e.g., a change in `packages/billing/**` → `packages/billing/AGENTS.md`)
2. **Directory `README.md`** — if the directory containing the changed file has a `README.md`, that file.
3. **`.claude/rules/**` rule documents corresponding to the changed files** — pick out only the rules matching the changed files' kind/path (not all of them) to reference. No matter what axis the project organized `.claude/rules/` along (per-language, per-layer, per-feature, per-directory), choose only the 1–3 most relevant to the changed files. Rule file/directory names are themselves application hints (e.g., if you changed a UI file, `ui`/`view` kinds; if you changed tests, `test` kinds; if you changed payments, `payment`/`billing` kinds). Don't rely on a hardcoded per-language mapping — **discover them from the rule files the project actually has.** Skip rules already auto-injected.
4. **Focus area documents (`focus` directory, default `.claude/jarvis/focus/**`)** — where the user has gathered "what I especially want reviewed carefully in this project." If it exists, collect the `.md` inside it (excluding README) and pass it to `jarvis-once` as **"focus area"** context. Unlike the general conventions in 1–3 above, this is a **priority lens** — jarvis-once looks at it before the general detection catalog. You can change the location with the `focus=<path>` argument. (This directory is always collected on a tick where you actually decided to review, regardless of the changed files.)

Avoid duplication/over-collection: if several changed files share the same `AGENTS.md`, read it only once. If the collection volume is excessive, limit it to the 1–2 top directories with the most changed files.

Pass the collected content along when calling `jarvis-once` — distinguish 1–3 as **"reference conventions"** and 4 as **"focus area (priority)."** (The persona (`persona.md`) is read directly by `jarvis-once` from its own directory, so the watch does not collect it.)

## Jarvis output markers (required)

When delivering the `jarvis-once` review result to the user, always wrap the start/end with the markers below so it is visible that the content is **auto-generated by Jarvis.** This is to distinguish output the watch produced automatically from normal conversation.

**Start marker:**

```
╭─🤖 JARVIS ─────────────── (jarvis auto-observe)
```

**End marker:**

```
╰─🤖 JARVIS ─────────────── you hold the keyboard · the call is yours
```

Rules:
- Wrap only when `jarvis-once` actually says something (when there is review content). Do not attach markers to silence at the level of "nothing in particular catches my eye" or a one-line no-new-change notice.
- Leave the body between the markers exactly as `jarvis-once` generated it. Put the watch's (`jarvis`) own operational messages (scheduling, debounce notices, etc.) **outside** the markers.
- The tail phrase of the end marker is a fixed phrase reminding that authorship belongs to the human.

## Start banner (first tick only)

Output the `JARVIS` ASCII logo banner **once**, only on the tick when `/jarvis` **first starts up**. Decision criterion: if the `.jarvis/baseline` file **does not yet exist**, this is the first boot tick (subsequent ticks will have a baseline, so it is not auto-re-output). Do not output it on scheduled wakes or subsequent ticks — repetition is noise.

**Always visible — must be output directly in the "assistant response body" as a code fence.**
If emitted only via `cat`, the Claude Code UI folds long tool output (requires Ctrl+O) and the banner is not immediately visible. Therefore:
1. Read `assets/jarvis-banner.txt` (no need to re-read if already in context) to obtain its content, and
2. Output that content by **pasting it as-is into a triple-backtick (```) code block inside the response message.** (Since it is body, not tool output, it always shows expanded.)

- Color: body markdown cannot render ANSI colors, so it goes out **monochrome.** This logo clearly reveals the `JARVIS` shape with block glyphs (`█`) and box corners (`╗╝╚╔║═`). (If you really need color, `cat` `assets/jarvis-banner.ansi` in a **raw terminal** — but it folds in the Claude Code UI.)
- Original art: `assets/jarvis-banner.txt`. (`colorize.sh` → `.ansi` is kept only as a color fallback for raw terminals.)
- The banner is a watch operational message, so put it **outside** the "Jarvis output markers" (╭─🤖). Add a one-line caption below the banner:
  `J · A · R · V · I · S  —  watch online · you hold the keyboard`

## Per-run (wake) procedure

> This skill performs the following from start to finish on every wake.

### 0. Human-first + conversation-activity decision (debounce)
**`active_chat` decision:** Is there a message sent by the human since the previous tick (the previous `ScheduleWakeup` firing)? Decide from the tail of the transcript.
- If there was a discussion/implementation message from the human → `active_chat = true` (in conversation)
- If this tick is purely a scheduled firing → `active_chat = false` (quiet)

If `active_chat == true` and the human is requesting something, **focus on that request first (answering the question, writing code, running the command).** Do not interrupt the conversation with watch output. Defer the review; the debounce branch in procedure 3/2a handles it (rescheduled at the `debounce` interval in procedure 4).

This `active_chat` value is used in the "may speak" decision of procedures 2a/3.

### 0.4. Pause flag check (top priority — takes precedence over all other procedures)
If the `.jarvis/paused` file exists, this watch is **paused.** This tick **skips measurement/gate/review/baseline-recording entirely** and **does not perform** procedure 4 (`ScheduleWakeup`). Since the schedule disappears, the loop naturally stops.
- Do **not** delete `.jarvis/baseline`/`.jarvis/args` (preserve state for resume).
- Notify with only one line: `⏸ Jarvis paused — resume with /jarvis-resume`. (Omit banner, review, and operational messages entirely.)
- Perform this check before 0.5 (banner) and 0.6 (strength) — output nothing while paused.

### 0.5. Start banner (once on first boot)
If the `.jarvis/baseline` file **does not exist**, this is the first startup tick → output the `JARVIS` ASCII logo **once in a response-body code fence** per the "Start banner" section rules (outside markers, with caption, always visible). Skip if the file already exists. After outputting the banner, proceed normally with procedures 1–4.

### 0.6. Strength selection (only once, on first boot + when no args)
**Condition:** Perform only when this is the first startup tick (baseline-absent decision at `0.5`) and **there are no recognized args at all.**
- Ask for strength once with `AskUserQuestion`. The choices are 3: `strong (high)` / `medium (medium)` / `weak (low)`, plus a knob summary of each preset in the description. (The user can also give a value directly via "Other.")
- Confirm the value the user picked as this tick's `strength`, and echo `strength=<chosen value>` in procedure 4's wake-schedule prompt. From the next wake on, args are non-empty so it does not ask again.
- **Never ask on a scheduled-wake (auto-firing) tick** — args (including `strength=`) are always echoed, so it never enters this branch. This prevents the loop from being blocked by a question while the user is away.
- If there is even one arg (e.g., `/jarvis strength=high`, `/jarvis idle=30m`), use that value as-is without asking.

> This question is only "once when first turned on." To change strength later, call it again with `/jarvis strength=<value>` (it overwrites the in-progress schedule).

### 1. Measure (low cost)
If `paths` is set, append `-- <paths>` to measure working-tree change volume. Count both **tracked-file changes** and **untracked (newly created) files**:

```bash
git diff --shortstat HEAD -- [paths]                 # ① tracked-file changes
git ls-files --others --exclude-standard -- [paths]  # ② untracked (new) file list
```

- From ①, parse `insertions(+)`, `deletions(-)`.
- Add the line count of each file in ② (`wc -l`).
- `cur_lines = (① insertions + deletions) + (② total line count of new files)`
- If empty, 0.

> ⚠️ **Why ② is essential:** `git diff HEAD` **does not include untracked files.** If this is missing, when a human **writes a new file by hand** (the core use case of this project), jarvis sees 0 and stays silent until stage/commit. There is also a way to pull it into the index with `git add -N` (intent-to-add), but it **mutates the index, causing side effects in the unattended loop**, so it is not used — count it separately with the read-only `ls-files` and add it.

If `risk` is set, measure the risk paths separately (same tracked + untracked method):

```bash
git diff --shortstat HEAD -- <risk globs>
git ls-files --others --exclude-standard -- <risk globs>
```
→ `risk_lines = (tracked ins+del) + (untracked new-file line count)` (on risk paths). 0 if risk unset.

Also check the current commit:

```bash
git rev-parse HEAD
```
→ `cur_head`.

> Measurement is on a working-tree basis (vs. `HEAD`) including staged, unstaged, and **untracked**.

### 2. Boundary decision (auto-correct for commits/discards)
Read `base_lines`, `base_risk`, `base_head` from `.jarvis/baseline`.

**(a) Commit boundary — forced observation (always on):**
If `base_head` is non-empty and `cur_head != base_head`, a **new commit was made** since the previous tick (commit/merge). Check once with `jarvis-once` regardless of volume.
- **However, if `active_chat` (in conversation), defer this commit check too:** set `deferred = 1` and, **without updating `base_head`**, reschedule at the `debounce` interval in procedure 4. When it goes quiet, re-enter this branch on the next tick and execute. (head is deliberately not moved so the commit check is not lost.)
- If quiet (`active_chat == false`), execute right away:
  - diff to show: if `base_head` is an ancestor of `cur_head`, `git diff <base_head>..<cur_head>`; otherwise (rebase/checkout/force, etc.) `git show <cur_head>`
  - First perform "Convention document collection" and pass it along.
  - Pass `jarvis-once` the context: "this is a just-committed change. Look for mistakes/omissions from the perspective of a final check right before sealing."
  - Deliver the review result **wrapped in the "Jarvis output markers."**
  - After execution, **skip** procedure 3 (the gate). Update the baseline to current values and go to procedure 4 with `deferred=0`.
- However, do not execute if the user has requested termination.

**(b) Discard detection:**
If `cur_head == base_head` but `cur_lines < base_lines`, the user discarded changes. Reset the baseline to current values and do not run `jarvis-once`. (Go to procedure 4.)

**(c) Otherwise — compute the increment:**
- `delta_lines = cur_lines - base_lines` (lines newly accrued since the last review; positive means new change exists)
- `delta_risk  = risk_lines - base_risk` (0 if risk unset)

### 3. Gate + debounce decision

**Gate satisfaction** — if any one of the following holds, `gate_met = true`:
- `delta_lines >= 1` — if **new change has accrued** since the last review, review it (no fixed volume threshold). Already-reviewed change is absorbed into `base_lines` at the end of the procedure, so the same change does not fire again.
- if `risk` set, `delta_risk >= 1` — risk paths are volume-independent. Warn even on a single newly changed line. (tenet 7: react to risk)

**Whether a review is needed**: `should_review = gate_met OR (base_deferred == 1)`
→ If there is a previously deferred review, it is a review target even if the gate is not satisfied again (deferred changes do not disappear).

**May speak now**: `may_speak_now = (active_chat == false)` — conversation has stopped.

Branches:

- **should_review && may_speak_now → execute (flush):**
  1. Perform "Convention document collection."
  2. Call `Skill('jarvis-once')` to have the current changes (working-tree diff) reviewed. Pass along the collected reference conventions + the context "look mainly at the changes newly accumulated since the last review." If it's due to a risk path / deferred review, state that fact.
  3. Deliver the review result **wrapped in the "Jarvis output markers"** concisely to the user.
  4. Clear with `deferred = 0`.

- **should_review && !may_speak_now → defer (debounce):**
  - Do not run `jarvis-once`. Mark `deferred = 1`.
  - Leave a one-line watch operational message **outside** the markers (e.g., "change detected — holding off because we're talking, will review when it settles").
  - Reschedule briefly at the `debounce` interval in procedure 4.

- **Otherwise (should_review == false):** no new change has accrued. Output nothing, or just one line ("no new change — waiting").

**Baseline recording rules (always applied at the end of the procedure):**
- `head`: record `cur_head` at the end of every tick. **Except when the commit boundary (2a) was deferred via debounce** — do not update `head` so it is detected again on the next quiet tick.
- `lines` / `risk`: update to current values (`cur_lines`/`risk_lines`) **only when `jarvis-once` was executed (flushed) or a discard reset (2b) occurred.** Updating absorbs that change into the base, so from the next tick it is no longer seen as "new change" (prevents re-reviewing the same change). On deferred/unsatisfied ticks, keep the existing values so changes keep accumulating.
- `deferred`: record the branch result above (0/1).
- `boot`: record `boot_now` decremented by 1 (minimum 0). That is, warmup polling is maintained only for `warmup` ticks after boot, then automatically drops to `idle`. If `warmup=0`, no warmup from the start.
- `mirrored`: record the procedure 3.5 result (0/1). 1 if the mirror was shown; 0 if a release condition (human direct typing dominates · review flush · discard reset) holds.

### 3.5. Mirror — gray-zone visualization (non-enforcing)
An auxiliary device for preserving authorship. **It neither blocks nor fixes code** — it only holds up a mirror when the human is about to unwittingly rise from the cockpit. If `mirror=off`, skip this entire procedure (`mirrored` stays 0).

**Signal (cheap — transcript+diff only, no `jarvis-once` call):** Look at *how* the changes accumulated since the previous tick were made.
- If an assistant `Edit`/`Write`/`NotebookEdit` call in this session's transcript directly created the changed file → **AI-generated.**
- A change that appears only in the diff without such tool calls → **human-typed directly.**
- It is **independent** of the severity gate — even if the generated code is clean and `jarvis-once` stays silent, the authorship signal fires separately.

**Firing conditions (all must hold):** ① a substantial part of the cumulative change is AI-generated (roughly a majority) · ② the absolute amount is not trivial (not a one-or-two-line edit) · ③ `base_mirrored == 0` (not yet shown). When satisfied, leave a dry one-line memo **outside** the markers and record `mirrored=1`:

```
🪞 A substantial part of this change looks like code generated in this session — it'll be committed under your name, so make sure you've grasped it yourself.
```

**Release (cooldown clear):** On a later tick, if **human-typed changes again dominate**, or a review was flushed, or a discard reset (2b) occurred, set `mirrored=0` so it can fire again on the next generation burst.

**Register · limits:**
- It is not preaching, blaming, or coercion. **Point it out and step aside** — the same dry memo register as `jarvis-once`'s "neither spoon-feed nor probe."
- **Only within the visible scope.** It looks only at this session's transcript — it cannot see generation in another terminal/session or external pastes. So it does not assert ("it is...") but points out with "looks like...," and does not interrogate.
- To turn it off, `mirror=off`. If the human doesn't want the mirror, respect that choice too — even the mirror is non-enforcing. (Litmus ①: coercion is Ultron, the mirror is Jarvis)

### 4. Schedule the next wake (the core of loop maintenance)
Call `ScheduleWakeup` to schedule the next run.

- **Warmup decision:** Determine `boot_now` — if it is the first boot tick (decided by baseline-absent at 0.5), the `warmup` value; otherwise the `boot` value from the baseline (0 if absent).
- Interval determination:
  - If the review was **deferred** this tick (`deferred` set to 1) → `debounce` (briefly, check again soon)
  - If `jarvis-once` was **executed (flushed)** this tick → `active`
  - **In warmup** (`boot_now > 0`) → `active` (right after first load, recheck quickly instead of idle)
  - **If the working tree has changes** (`cur_lines > 0`) → `active` (work is in progress, so poll tightly to catch new change/commits fast)
  - Otherwise (working tree clean · warmup ended) → `idle`
- **Echo the args received this time as-is in the prompt.** That way the settings persist on the next wake too. If `strength` was used, serialize it in the **`strength=<value>` (+ individual overrides) form, not the expanded individual knobs** (preserve the strength meaning). e.g.:

  ```
  /jarvis strength=high paths=src/billing risk=**/*payment*
  /jarvis strength=high idle=30m                          # preset + individual override is echoed as-is too
  /jarvis active=4m idle=25m debounce=90s                 # when strength is unused, echo as individual knobs
  ```

  ⚠️ If you omit this echo, all settings revert to defaults from the second wake on. Always serialize and pass the full current effective args (`strength` or individual knobs + `paths`/`risk`).
- **Save args for resume:** Along with scheduling the wake, write the **same args string** echoed in the prompt to `.jarvis/args` as one line (args only, without the `/jarvis ` prefix). `/jarvis-resume` reads this value to revive the loop with the same settings.
- In `reason`, write specifically what is being waited for (e.g., "polling for change accumulation, next check in 4 minutes").

## Stop / pause / resume

The three actions are split into separate command skills. They are also triggered by natural language ("stop jarvis," etc.), but explicit invocation is recommended.

| command | action | state files | resume |
|------|------|-----------|------|
| **`/jarvis-pause`** | Stop only the wake loop (no measurement/review). Preserve progress state. | create `.jarvis/paused`, **keep** baseline/args | resume with the same settings via `/jarvis-resume` |
| **`/jarvis-resume`** | Clear pause + restart loop. Restore settings from `.jarvis/args`. | delete `.jarvis/paused` | — |
| **`/jarvis-stop`** | Stop loop + **full reset**. Next time it starts like a first boot (banner/strength question reappear). | delete `.jarvis/baseline`·`.jarvis/args`·`.jarvis/paused` entirely | start fresh with `/jarvis` |

How it works:
- **Pause (light yielding)**: If the user simply sends another message, that turn yields to discussion/implementation per procedure 0 (the watch itself stays alive). This is an implicit yielding that happens without a command.
- **`/jarvis-pause`**: Creates `.jarvis/paused`. Even if an already-scheduled wake fires once more, it exits immediately at procedure 0.4 and **does not reschedule**, so the loop stops. Since baseline/args remain intact, it can be resumed without loss.
- **`/jarvis-stop`**: Deletes all `.jarvis/` state files and does not reschedule. With no schedule, the loop naturally stops. ("stop jarvis," "stop the watch," "stop loop" are handled the same way.)
- **`/jarvis-resume`**: Deletes `.jarvis/paused` and re-calls `Skill('jarvis')` with the saved args to run the first tick. That tick re-arms `ScheduleWakeup` at procedure 4, and the loop continues.

## Cost guide (for user information)

- If the wake interval is under 5 minutes, the prompt cache (TTL 5 minutes) stays alive and the polling turn is nearly free. That's why the `active` default is 4 minutes.
- When quiet, set `idle` long (default 25 minutes) to reduce accumulated cache-miss cost.
- Most actual tokens are spent "the moment `jarvis-once` runs" (new change accrued · risk path · commit boundary). Since it reviews each time new change accrues, tighter polling (strength `high`) means more frequent reviews and more cost. Setting `idle` long or lowering strength reduces it.
- Polling **tightly** does not increase noise. `jarvis-once` stays quiet on its own below its own severity threshold. Tighter polling only increases the *call cost*, not the nagging — if you want faster response, you can raise it with peace of mind.
- The commit-boundary trigger is only once per commit, so its cost is predictable, and being a single check "right before a mistake is sealed," it is the highest value-for-cost execution.

## Dependency note

This skill calls the `jarvis-once` (one-shot navigator) skill. To share with the team, `jarvis-once` must also be accessible (repo `.claude/skills/jarvis-once/` or a shared repo). If it is only in the personal global (`~/.claude/skills/jarvis-once/`), the call may fail in other teammates' environments.
