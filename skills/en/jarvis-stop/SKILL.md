---
name: jarvis-stop
description: Fully shuts down and resets the jarvis watch. In addition to stopping the wake loop, it deletes all of the .jarvis/baseline·args·paused state files. The next /jarvis starts from a first boot (banner, strength question). Use on requests like "stop jarvis", "halt the watch", "jarvis stop", "fully shut down the watch".
---

# jarvis-stop

**Fully shuts down** the `jarvis` watch. In addition to stopping the wake loop, it deletes all control state files in `.jarvis/` (`baseline`·`args`·`paused`) to **return to the initial state.** The next time you call `/jarvis`, it starts fresh as if it were a first boot (start banner + strength question).

> To pause briefly and continue with the same settings, use `/jarvis-pause` rather than `/jarvis-stop` (state preservation). `/jarvis-stop` **discards everything, including the accumulated change tracking and the saved strength.**

## How it works

The jarvis loop is structured so that the `ScheduleWakeup` reservation calls the next tick in a self-paced manner. `/jarvis-stop` **does not reschedule** and deletes the loop state files. Even if an already-scheduled wake fires one more time, with no baseline it is treated as a first-boot tick, or with no paused flag it simply runs a new tick — for a clean shutdown, the state is left empty.

## Procedure

1. **Delete state files in bulk**:

   ```bash
   rm -f .jarvis/baseline .jarvis/args .jarvis/paused
   ```

   - The `.jarvis/` directory itself may be left in place (there may be other caches). Even if it is empty, there is no need to delete it.

2. **No rescheduling**: **Do not call** `ScheduleWakeup`. With no reservation, the loop stops naturally.

3. **Report** (one line): `🛑 Jarvis watch shut down + state reset. To turn it back on, /jarvis (starts fresh from the banner and strength question).`

## Natural-language triggers

Treat shutdown intents like "stop jarvis", "halt the watch", "stop loop", "fully shut down the watch" the same as this skill (full reset). If the nuance is just a pause ("pause for a bit", "back again later"), suggest `/jarvis-pause`.

## What it does not do

- Does not call `ScheduleWakeup`.
- Does not touch the code/changes in the user's working tree — it only deletes the `.jarvis/` control files.

## References
- Watch core: `.claude/skills/jarvis/SKILL.md` ("control state files" table)
- Pause (state preservation): `.claude/skills/jarvis-pause/SKILL.md`
- Resume: `.claude/skills/jarvis-resume/SKILL.md`
