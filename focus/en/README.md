# jarvis focus area

Collect, as markdown, **what you want reviewed especially carefully in this project** in this directory.
When `jarvis-once` reviews, it reads these documents as **"focus area" context, ahead of the generic detection catalog.**

The more concrete and project-specific the notes, the more accurate the navigation — over vague, all-encompassing context.

## What to put here (examples)
- `concurrency.md` — this service's concurrency/locking rules, shared state that's dangerous to touch
- `payment-invariants.md` — invariants in payment-amount calculation that must never break
- `known-traps.md` — past incident sites, recurring mistake patterns

Files are free-form. If only this README is here (no other docs), it just does a normal review with no focus area.

> This directory can be committed and **shared with the team**. To keep it personal, add it to `.gitignore`.
> To change its location, use `/jarvis focus=<path>` (default `.claude/jarvis/focus/`).
