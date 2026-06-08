---
name: jarvis-reset
description: Deletes the jarvis watch's local state (.jarvis/baseline·args·status) for a full reset. The next /loop /jarvis starts from a first boot (banner, strength question). This does not stop the loop itself — it is an independent command that just clears the accrued tracking and saved strength. Use on requests like "reset jarvis", "jarvis reset", "clear the watch state", "start over".
---

# jarvis-reset

**Resets the local state** of the `jarvis` watch. It deletes the state files in `.jarvis/` (`baseline`·`args`) to **discard all accrued change tracking and the saved strength.** The next time you launch `/loop /jarvis`, it starts fresh as if on a first boot (start banner + strength question).

> ⚠️ **This is not a command to stop the loop.** To stop a running watch, interrupt the `/loop` itself (Esc). `jarvis-reset` is **independent** of that and only clears *state*. Use it when you want a clean restart after stopping.

## Why an independent command

`/loop /jarvis` continues from `.jarvis/baseline`·`args` if they are present (that is what "resume" means). So when you want "fresh from scratch," you must explicitly clear that state — which is this skill's job. Loop termination (Esc) has no teardown hook, so a reset only ever happens via this **separate command**.

## Procedure

1. **Delete state files in bulk**:

   ```bash
   rm -f .jarvis/baseline .jarvis/args .jarvis/status .jarvis/paused
   ```

   - `.jarvis/status` is the liveness state file; deleting it clears the statusline immediately (shows watch not running).
   - `.jarvis/paused` may be a leftover from an older version; delete it too (harmless if absent).
   - The `.jarvis/` directory itself may be left in place (there may be other caches). Even if empty, there is no need to delete it.

2. **Report** (one line): `🧹 Jarvis state reset. To turn it back on, /loop /jarvis (starts fresh from the banner and strength question).`

## Natural-language triggers

Handle reset intents like "reset jarvis", "jarvis reset", "clear the watch state", "start over" with this skill. If the nuance is only *stopping* ("just stop", "pause for a bit"), tell the user to interrupt the loop (Esc) — leaving the state in place lets `/loop /jarvis` resume from where it left off.

## What it does not do

- Does not directly stop a running `/loop` (that's Esc's job).
- Does not touch code/changes in the user's working tree — it only deletes the `.jarvis/` control files.

## References
- Watch core: `.claude/skills/jarvis/SKILL.md` ("control state files" table, start-time resume & self-correction)
