---
name: jarvis-pause
description: Pauses only the wake loop of the jarvis watch. It preserves the baseline·args progress state, so /jarvis-resume can pick up from the same settings. Use on requests like "jarvis pause", "pause the watch for a bit", "jarvis pause".
---

# jarvis-pause

Stops **only the wake loop** of the `jarvis` watch. It stops measuring, reviewing, and rescheduling, but **preserves the progress state (baseline·args)**. Later, when you call `/jarvis-resume`, it resumes from the stopped point with the exact same settings.

> To fully turn it off and reset, use `/jarvis-stop`; to turn it back on, use `/jarvis-resume`.

## How it works

The jarvis loop is a self-paced structure where, with no separate daemon, the `ScheduleWakeup` reservation itself triggers the next tick. So "pausing" means making it **not schedule the next reservation**.

`/jarvis-pause` creates a `.jarvis/paused` flag file. Even if an already-scheduled wake fires one more time, jarvis procedure 0.4 (top-priority pause check) makes it exit immediately and **not reschedule**, so the loop stops naturally. `.jarvis/baseline`·`.jarvis/args` are left untouched, so it can resume without loss.

## Procedure

1. **Ensure the directory**: If `.jarvis/` does not exist, create it.

   ```bash
   mkdir -p .jarvis
   ```

2. **Create the pause flag**: Leave a one-line, human-readable note (the content is free-form; its mere existence is the flag).

   ```bash
   printf 'paused by /jarvis-pause\n' > .jarvis/paused
   ```

3. **Check state, then report** (one line):
   - If `.jarvis/baseline` exists → `⏸ Jarvis watch paused. Progress state preserved — resume from where it left off with /jarvis-resume.`
   - If `.jarvis/baseline` does not exist (the watch never actually ran) → `⏸ There was no active watch, but the pause flag has been set. Even if there is a scheduled wake, it will not restart. You can start with /jarvis-resume.`

## What it does not do

- Does not call `ScheduleWakeup` (does not keep the loop alive).
- Does not delete `.jarvis/baseline`·`.jarvis/args` (that's `/jarvis-stop`'s job).
- Does not print banners, reviews, or operational messages — it ends with a one-line report.

## References
- Watch core: `.claude/skills/jarvis/SKILL.md` (procedure 0.4 pause check, "control state files" table)
- Resume: `.claude/skills/jarvis-resume/SKILL.md`
- Full stop: `.claude/skills/jarvis-stop/SKILL.md`
