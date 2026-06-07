---
name: jarvis-resume
description: Restarts the jarvis watch wake loop that was stopped by /jarvis-pause. It restores the previous settings (strength, etc.) saved in .jarvis/args and continues running at the same strength. Use on requests like "jarvis resume", "turn the watch back on", "jarvis resume".
---

# jarvis-resume

**Turns back on** the watch that was stopped with `/jarvis-pause`. It removes the `.jarvis/paused` flag and revives the loop by running `jarvis`'s first tick with the saved settings (`.jarvis/args`).

> Since the baseline is preserved, it keeps watching from the stopped point (accumulated changes are kept too). To start fresh from a fully reset state, use `/jarvis`, or (after resetting first) `/jarvis-stop` → `/jarvis`.

## Procedure

1. **Remove the pause flag**:

   ```bash
   rm -f .jarvis/paused
   ```

2. **Restore saved settings**: If `.jarvis/args` exists, read its one line and use it as args. If it does not exist (previously stopped, or first time), start with no args at the medium default.

   ```bash
   cat .jarvis/args 2>/dev/null || true
   ```

3. **Restart the loop**: Call the `jarvis` skill with the restored args — `Skill('jarvis', args=<restored args>)`. (If args is empty, call `Skill('jarvis')` with no argument.)
   - This call performs jarvis's first tick, and that tick sets `ScheduleWakeup` again in procedure 4, so the self-paced loop continues.
   - Since the baseline already exists, the start banner (procedure 0.5) and the strength question (procedure 0.6) are automatically skipped — it resumes silently.

4. **Report** (one line): `▶ Jarvis watch resumed (<restored strength, etc.>). Continuing to watch.`

## Edge cases

- **`.jarvis/paused` was not there to begin with**: Already running or already stopped. Even so, harmlessly run one tick with `Skill('jarvis')` to ensure the loop (this is safe since jarvis only sets one reservation per tick, avoiding duplicates).
- **`.jarvis/baseline` is also missing**: Completely fresh state → `jarvis` operates as a first boot (banner, strength question appear). Normal.

## What it does not do

- Does not delete `.jarvis/baseline`·`.jarvis/args` (since this is a resume, preservation is the key).

## References
- Watch core: `.claude/skills/jarvis/SKILL.md`
- Pause: `.claude/skills/jarvis-pause/SKILL.md`
- Full stop: `.claude/skills/jarvis-stop/SKILL.md`
