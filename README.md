<div align="center">

**English** | [한국어](README_kr.md)

# Project — Machine in the Loop

### You hold the keyboard. The machine works the loop.

**jarvis** is a **Claude Code watch loop** that observes your changes while *you* write
the code, and wakes a pair-navigator automatically only at the moments that matter.
The human writes the code; the AI stays an observer.

🔗 **[View on the web](https://pinguding.github.io/Project-Machine-in-the-loop/)**

`/loop /jarvis`  ·  `strength=medium`  ·  `risk=**/*payment*`  ·  `debounce=90s`

</div>

---

> **This is not a magic wand that turns a day of work into ten minutes.**
> But it can turn eight hours into three or four — and keep that pace *sustainable*.

---

## The Philosophy

A way of pair-developing with AI that **preserves authorship**. jarvis is not just an
automation tool; it starts from a single stance — **the author of the code must remain the human, all the way through.**

This is not a retreat to the pre-agent era. It is a call to **redefine AX (AI Experience) around the human.**
Not turning back the clock — turning the wheel.

### Why "jarvis" · The Name

Jarvis **amplifies** Tony Stark's ability. But the one who actually wears the suit, **fights, and
makes the call is Tony, to the end** — he receives information and assistance from Jarvis, but never
hands over the controls. Jarvis surfaces things on the side; the decisions and the actions are Tony's.

Today's coding agents drift the other way easily — not because the automation is too capable, but
because they build the structure of **"it's my code, yet I'm not in the cockpit"** — a structure that
pushes the human *out* of the decision loop.

> That's why the name is Jarvis — **the AI that keeps the human in the cockpit.**

### Human in the loop ✗ vs Machine in the loop ✓

|  | **✗ Human in the loop** | **✓ Machine in the loop** |
|---|---|---|
| Structure | The AI writes, the human reviews & approves | The human writes, the machine assists inside the loop |
| Result | Review-as-observer breeds **false metacognition**. Understanding accumulates in the tool, not the human, and errors become already-committed code someone must later dismantle. | The implementation stays in the human's hands as **long-term memory**. The machine remains an observer and guides the way, but the human holds the keyboard to the end. |

The crux is **flipping ownership of the loop**. A human stepping into an AI-made loop to "review" is,
cognitively, the easiest game to lose — so instead the human owns the loop, and the machine assists inside it.

---

### Diagnosis — the failure path of full automation

When performance fell short of expectations, the industry's prescription became *"inject refined context →
engineer your prompts → context, context, more context,"* and AI-native shops hardened that into the
structure **"the human doesn't write code, just supplies detailed context."** The disease that structure breeds:

- A bug appears, but the developer **can't tell what to fix** → runs straight to the AI: "fix this for me."
- Simple errors don't show, but for **multi-layered, compound causes** the AI can't grasp it and the human grasps it even less → resolution time explodes.
- You can spit out eight features in a snap, yet **never reach minimum shippable quality.** Generation speed isn't throughput — the bottleneck moved to *comprehension and debugging*, and that muscle has gone slack.
- In the end the human **loses the initiative.** They don't know the code; not writing it, their "feel" dulls; and **juniors are robbed of the chance to grow.**

The dividing line isn't *"to use AI or not."* It's **"does the human hold the command — the judgment of *what* to delegate?"**
Having the AI generate boilerplate is no problem. But trying to automate *that judgment itself* with a "universal rule"
is full of paradox — it hands the very initiative of deciding-what-to-delegate back to the machine.
The human must remain the **router / classifier** to the end.

### gray zone — another name for false metacognition

**gray zone = the region you don't actually know, yet are (self-)judged to know.**

- **Generation** lays down the "where it lives + the algorithmic process" as **episodic memory** — long and concrete.
- **Reading (review)** leaves only **recognition-level familiarity**, which then masquerades as "understanding."
  The illusion of "I skimmed it, so I know it" — even the illusion of authorship: "it feels like I made this."

The more full automation accumulates, the wider this gray zone grows. That's why lifting the human's cognition
back up is what creates sustainability — one of jarvis's strongest pillars.

### Sustainability — not "speed" but "integrated speed"

```
speed
 │      ╱‾‾╲          ← full automation: an early burst (a day → ten minutes)
 │     ╱    ╲___        but the gray zone widens and velocity collapses
 │    ╱         ╲__     (the wall of "built eight features, none ship-quality")
 │   ╱
 │  ╱━━━━━━━━━━━━━━━  ← Machine in the loop: a lower peak (8h → 4h) held flat
 │ ╱                    the gray zone stays bounded, so it doesn't cave in
 └────────────────────▶ time
```

Full automation's speed is **a loan at compound interest.** As fast as you go now, the gray zone widens, and
you repay it — with interest — in maintenance and rework ("start over from scratch"). Machine in the loop has a
lower peak but **takes on no debt.** Measured as *integrated speed (cumulative throughput)* rather than instantaneous
speed, this side wins.

### The asymmetry of error cost — is the human in the filter seat?

The same **3% hallucination** acts in opposite directions across the two structures.

- **3% under full automation:** the hallucination is sealed straight into the final artifact. The human didn't write it (false metacognition), isn't even positioned to filter it, and that 3% becomes committed code someone must later find and dismantle. Every automation cycle compounds the drift. → **Catastrophic.**
- **3% in the navigator (jarvis):** the same 3% is merely noise riding on **97% accurate navigation.** Here **the human sits in the filter seat.** If the AI talks nonsense, you **cleanly ignore it and get on with your work.** Discard cost ≈ 0, and only human-written code lands in the artifact. → **Harmless — net positive, even.**

The real axis dividing the two structures is **whether the human occupies the filter seat.**

> **The kill-shot, against "better models will solve it":**
> A better AI doesn't shrink the gray zone — it **widens** it. The more plausible and correct the code looks, the
> *more convincingly* the "I know this" illusion takes hold. Sloppy code at least invites suspicion; flawless-looking
> code kills the urge to verify outright. So the gray zone is **immune to model improvement** — this argument's weight
> rests not on the contingent "3% hallucination" but on the permanent **structure of human cognition.**

### Accountability cannot be delegated

So what if, between wakes, the human has the AI write everything and only takes the review? — **that, too, is the
human's call.** jarvis does not force it. The moment it forces anything, it is taking the choice away from the human.

Instead, the real gate isn't a tool's teeth — it's **accountability.**

> Labor can be delegated. But **accountability cannot.**
> The moment your name is on the commit, it is something you must answer for.

People **don't sign their name to what they don't understand.** The instant accountability becomes non-delegable,
the human is pulled back to the keyboard on their own. This is the *structural* gravity that stands in for jarvis's
missing teeth.

You might call this "an irresponsible design that offloads onto individual discipline" — but it's the **opposite.**
What *diffuses* responsibility is full automation ("but the AI wrote it"); Machine in the loop **concentrates** it on
one person ("your name, your commit"). It puts *more* responsibility on the human, not less.

> **The precondition (stated honestly):** all of this presupposes a culture where the name on a commit actually means
> something (real code review, you fix your own bugs, on-call). Where accountability is diffuse, no tool can substitute
> for it — but that is a different, already-severed-feedback-loop problem.

### The mirror — so accountability isn't blinded by the gray zone

For accountability to pull the human in, the human must **know that they don't know.** But the very essence of the
gray zone is "not knowing while feeling that you know." So accountability alone can fall short.

The mirror fills that gap — not as force, but as **light that makes accountability honest.** When a large share of the
accrued change is *generated code*, jarvis neither blocks nor fixes; it just holds up one line:

```
🪞 Much of this change looks generated this session — it'll ship under your name; confirm you actually grasp it.
```

Without taking the keyboard, it lets the one who signs **sign with their eyes open.** (Turn it off with `mirror=off` —
even the mirror is non-coercive.)

### A guide, not a producer

What Jarvis gives the human is only three things. What they share — all are **guidance**, not **production.**

| Point out what's missing | Suggest a better approach | Show the next step |
|---|---|---|
| "this part seems left out" | "this logic would be more efficient" | "next, you could do this" |

**Exactly the roles of pair coding.** The driver (the human) holds the keyboard and writes the code — forever the
human's seat. The navigator (Jarvis) reviews, looks ahead, and suggests direction. The single rule:
**"the navigator never takes the keyboard."**

### The navigator's register — flag it and step back

The navigator flags things with a **dry memo.** It neither spoon-feeds (answers, directives) nor quizzes (questions,
tests) — both seat the human as a passive responder. It marks the concern with a "needs checking" and steps back.
If you don't know, *you* go find out (by any means — AI or not; the human decides).

- ❌ Spoon-feed: *"line 40 is missing a null check, fix it like this"*
- ❌ Quiz: *"did you think about what happens when the input is empty?"*
- ✅ Memo: *"input could be empty here — this case needs checking"*

> **It helps you sit down at the desk; it does not read the book for you.**

### The litmus test

For every feature you add, you ask: ① Does this seat the human *more* firmly in the cockpit, or push them *out* of it?
② Did Tony say go (always-allowed · delegated · forbidden — which one)? If it doesn't pass, it isn't Jarvis, however convenient.

---

## How it works — watch cheaply, wake only when it's risky

The polling itself is a single `git diff`, so it burns almost no tokens. The expensive Jarvis review runs only when
new change has accrued since the last review, a risk path changed, or a commit boundary is crossed — **minimizing token spend.**

1. **Measure** — every wake, gauge the working-tree changed lines, risk-path changes, and current `HEAD`. Counts both tracked changes **and untracked (new) files.** Tokens ≈ 0.
2. **Boundary check** — Was there a new commit? Was a change reverted? Auto-corrects by comparing against the marker (`.jarvis/baseline`).
3. **Gate + debounce** — if any of new-change / risk / commit-boundary is met, it's review-worthy. But **if a conversation is live, defer**, and flush the accrued change at once when it goes quiet.
4. **Collect conventions & personalization → Jarvis** — gather the changed files' AGENTS.md / README / path rules + persona + focus area, pass them as context, and call Jarvis. The result is wrapped in markers.
5. **Schedule the next wake** — uses `ScheduleWakeup` to pick its own next run. Launch it as `/loop /jarvis` so the loop keeps going.

> Repetition rides on **`/loop`'s self-paced mode**, with `ScheduleWakeup` picking each interval. `ScheduleWakeup` only fires
> inside `/loop`, so the entry is always **`/loop /jarvis`**. Every tick schedules the next wake at its end, and
> stopping is simply interrupting the `/loop` (Esc) — no next wake gets scheduled. Re-running `/loop /jarvis` resumes; `/jarvis-reset` wipes state.

---

## Core features — reacting to risk, not volume

| | Feature | Description |
|---|---|---|
| 📏 | **New-change gate** | When **new change has accrued since the last review** (any amount — no fixed line/file threshold), it reviews. It fires once per accrual, never re-reviewing the same change. The AI shows up only after the human has written something themselves. |
| 🎯 | **Risk-path trigger** | Risk paths like payments and login fire **immediately on a single changed line**, regardless of volume. It never misses the "small but fatal." |
| 🔒 | **Forced commit-boundary watch** | When a new commit is detected, it checks once regardless of accrued volume. **Right before a mistake is sealed into code** is the golden moment to warn. |
| ⏸️ | **Conversation debounce** | During live conversation it defers the review, then handles the accrued change at once when things go quiet. **It doesn't break your flow.** |
| 📚 | **Automatic convention collection** | Gathers the changed files' nearest AGENTS.md, directory README, and path-specific team rules. Reviews knowing even "this package's rules." |
| ♾️ | **Self-paced watch** | Launched as `/loop /jarvis`, `ScheduleWakeup` picks each next interval itself — **it keeps watching with no further input.** |
| 🎭 | **Navigator personalization** | Fill in the empty `persona.md` to set **who** Jarvis is like and **what** it's sensitive to. |
| 🔬 | **Focus area** | Drop "what to watch especially in this project" into `.claude/jarvis/focus/`, and it's seen as a **priority lens** ahead of the generic catalog. |
| 🪞 | **gray-zone mirror** | When a large share of accrued change is **generated code**, it holds up one line — "did you actually grasp it?" It neither blocks nor fixes; just the mirror. |

---

## Transparency — the Jarvis output markers

A review the AI generated automatically is visually distinct from ordinary conversation. Between the markers is Jarvis
speaking; outside is the watch's operational message. The closing line reminds you, every time, where authorship lives.

```
# the deferred review flushes as the conversation goes quiet
╭─🤖 JARVIS ─────────────── (jarvis auto-observe)
input could be empty here, and checkout.total() references the empty
array directly — could lead to a crash. needs checking for empty input.
· ref: packages/checkout/AGENTS.md (boundary-case rules)
╰─🤖 JARVIS ─────────────── you hold the keyboard · the call is yours
```

**It stays an observer.** Jarvis does not edit code directly. It only reviews, flags, and suggests next steps, and
switches to implementation **only when the human delegates** — "fix this for me."

---

## Liveness — is it looping right now?

`/loop` has no resident process, so between ticks nothing runs and it's easy to lose track of whether the watch is
still alive. Jarvis signals it in two layers:

- **Tick heartbeat** — even on a quiet tick (no new change), it leaves one line: `⏱ jarvis · alive · next check ~4m (active) · strength=medium`.
- **Status line** — every tick writes `.jarvis/status`, and a bundled script (`assets/statusline.sh`) renders the
  watch state on every UI render — *between* ticks too. If the next wake time passes with no update, it even infers a stall:

```
🤖 jarvis · watching · next ~3m (active)              # alive
🤖 jarvis · ⚠ stalled? no tick for 11m — /loop /jarvis to resume
```

Enable the status line yourself (install never touches your `settings.json`):

```json
{ "statusLine": { "type": "command", "command": "bash ~/.claude/skills/jarvis/assets/statusline.sh" } }
```

It prints nothing when the watch isn't running, so it's safe to leave always on.

---

## Layout — `.claude/skills/`

| Skill | Role |
|------|------|
| **jarvis** | The entry-point watch loop. Launched as `/loop /jarvis`. Polls cheaply with `git diff`, and when new change accrues / a risk-path changes / a commit-boundary is crossed, calls `jarvis-once` and picks its next tick with `ScheduleWakeup`. |
| **jarvis-once** | The single-shot pair navigator. Only reviews, flags, and suggests next steps — **never writes code directly.** |
| **jarvis-reset** | Independent command that deletes the `.jarvis/` state (baseline & args) for a full reset. Does not stop a running loop (that's Esc); use it for a clean start afterward. |

State is stored in the working tree's `.jarvis/` (gitignored, an independent local state per clone). It avoids `.git/`
because writing inside `.git/` prompts for permission every time — unfit for an unattended loop.

---

## Personalization — distrusting vague, all-encompassing context

Accurate navigation comes from concrete, specific context. So instead of hardcoded universal rules, jarvis reads **the
documents the project actually has** (CLAUDE.md, AGENTS.md, path-specific rules, etc.) and personalizes in two layers:

- **`.claude/skills/jarvis-once/persona.md`** — defines *who* the navigator is + *what* it's sensitive to.
  **Ships empty**; fill it and the review's character shifts to the person/team. (Empty → the default navigator.)
- **`.claude/jarvis/focus/`** — a directory collecting what to review *especially carefully in this project.*
  Seen ahead of the generic detection catalog. Can be committed and shared with the team. Relocate with `/loop /jarvis focus=<path>`.

Whatever you personalize, the core rules — **"no code production · neither spoon-feed nor quiz"** — always hold.

---

## Configuration — tune with one line of args

```
/loop /jarvis strength=high risk=**/*payment* debounce=90s
```

| Key | Meaning | Default |
|---|---|---|
| `strength` | Strength preset — sets the polling-interval knobs below as a bundle (`low`/`medium`/`high`) | `medium` |
| `risk` | Risk-path glob — warns immediately, regardless of volume | `off` |
| `debounce` | Idle time after which a conversation is considered settled | `90s` |
| `active` | Wake interval when the working tree has changes / right after a review | `4m` |
| `idle` | Wake interval when the working tree is clean | `25m` |
| `warmup` | Number of fast-polling ticks right after first load | `3` |
| `paths` | Restrict the watched paths | all |
| `focus` | Focus-area directory | `.claude/jarvis/focus/` |
| `mirror` | gray-zone mirror (non-coercive) | `on` |

> 💡 **Polling tightly doesn't add nagging.** Jarvis stays silent below its own severity bar, so tighter polling
> only adds *call cost*, not noise. If you want faster response, raise the strength without worry.

---

## Usage

```
/loop /jarvis                # asks for a strength once, then starts the watch
/loop /jarvis strength=high   # check small changes often
/loop /jarvis strength=low    # only large chunks, rarely
/loop /jarvis risk=**/*payment*  # risk paths warn immediately, regardless of volume
/loop /jarvis mirror=off      # turn off the gray-zone mirror (on by default)

# stop/pause  → interrupt the loop (Esc)
# resume      → /loop /jarvis again (restores saved settings)
# full reset  → /jarvis-reset
```

> ⚠️ **Don't give `/loop` its own interval.** Launch as `/loop /jarvis` (no interval) so it self-paces — jarvis's `active`/`idle`/`strength` args drive the cadence via `ScheduleWakeup`. `/loop 5m /jarvis` runs on a fixed schedule and **ignores** those args. Tune the interval the usual way: `/loop /jarvis active=3m idle=20m`.

### Install

The installer asks you to **choose a language** (English or Korean skills), then installs into the current
project (`.claude/skills/`), sets up the focus directory, and gitignores `.jarvis/`.

One line (self-clones from this repo):

```bash
curl -fsSL https://raw.githubusercontent.com/pinguding/Project-Machine-in-the-loop/main/install.sh | bash
```

Or clone and run with options:

```bash
git clone https://github.com/pinguding/Project-Machine-in-the-loop.git
./Project-Machine-in-the-loop/install.sh                  # current project, asks for language
./Project-Machine-in-the-loop/install.sh --lang en        # English skills, no prompt
./Project-Machine-in-the-loop/install.sh --lang ko <path> # Korean skills into a specific project
./Project-Machine-in-the-loop/install.sh --global         # into ~/.claude/skills/ (every project)
```

Then open Claude Code in that project and run `/loop /jarvis`. Re-running the installer is safe (idempotent) and updates the skills in place.

> Skill sources live **in the open** under `skills/en/` and `skills/ko/` (not hidden in `.claude/`). The installer
> copies the language you pick into the target's `.claude/skills/`, which is where Claude Code discovers them.

---

## The Closing Question

> **"During the few hours an AI service is down, should our work be down too?"**

The deeper you lean on full automation, the more those hours leave us **unable to do anything** — because the
understanding sits in the tool, not in us. For us to keep moving steadily even when the tool briefly vanishes, shouldn't
the understanding of the code be stored **more in us than in the tool?**

**jarvis is one answer to that question.**

---

## License

This work is licensed under [**CC BY 4.0**](LICENSE). Use, share, and adapt it freely —
including the **Machine in the Loop** concept and the jarvis skills, even commercially —
but **give appropriate credit**: link back to this repository and indicate if you made changes.

> "Machine in the Loop (jarvis)" by pinguding — https://github.com/pinguding/Project-Machine-in-the-loop

<div align="center">

---

**jarvis · Machine in the Loop**
Claude Code Skill — `.claude/skills/jarvis/` · navigator: `jarvis-once`

</div>
