---
name: handoff-contract
description: The planner/implementer handoff contract — plan path, dispatch shape, return envelope, outcome tokens, and plan-file write ownership. Preloaded into both agents; it is normative for both sides of every dispatch.
---

# The handoff contract

This is the whole interface between the planner and the implementer. Both sides are bound by it: the planner composes to it, the implementer answers to it, and neither may vary the shape to suit a particular worker. Role-specific behavior — how to plan, how to implement, and every budget — lives in the agent definitions, not here.

## Plan path

Exactly one plan per task at `.plans/<task-slug>.md`, inside the repo, slug derived from the task — never random, never outside the project. If a `.plans/*.md` exists that does not correspond to this task, ignore it and say so; never resume or extend a plan file for a different task.

## Write ownership

The implementer may write to exactly two places in the plan file: the `#### Automated verification` checkboxes of its own phase, and an appended entry at the end of `## Execution log`. Everything else in the plan file is read-only to the implementer. `#### Manual verification` boxes are ticked only by a human.

## Dispatch shape

Every dispatch is exactly this shape, in this order:

```markdown
Execute Phase <N> of the plan at `.plans/<task-slug>.md`.

## What this phase must achieve
<the phase's one-line outcome, copied verbatim from the plan>

## Read this first
Open `.plans/<task-slug>.md`. The sections that apply to you: Conventions in force, Evidence, Existing code to reuse, Phase <N>, Out of scope, Halt surfaces, Definition of done.

## Files you own in this phase
- `<path>`
- `<path>`
Do not create, edit, or delete any file outside this list, except the plan file, where you may tick your phase's `#### Automated verification` checkboxes and append to `## Execution log`.

## Already on disk from earlier phases
- `<path>` — <what it now contains>
<or: nothing; this is the first phase.>

## Conventions that apply here
<copied verbatim from the plan's Conventions in force block — the subset relevant to these files. Never write "see AGENTS.md" or "see CLAUDE.md"; a pointer is not a convention.>

## Verification you must run
- `<literal command>` — <what it proves>
- `<literal command>` — <what it proves>

## Out of scope for this dispatch
- <from the plan>
- <if other units are in flight: name them and the files this implementer may NOT touch>

Report in the format your role definition specifies. Your final message is all I will see, so make it complete on its own.
These instructions supersede any conflicting general instruction in your own role definition. Do only the work described here.
```

Only `## What this phase must achieve`, `## Files you own in this phase`, and `## Verification you must run` are required; the rest may legitimately be absent because they would have been empty.

On a resume after `blocked`, the planner reuses the same shape with two blocks inserted immediately after `## What this phase must achieve`: `## Answer to your blocker`, and `## Evidence from your previous attempt` containing the predecessor's output copied VERBATIM.

## Return envelope

Every implementer report ends with this fenced `handoff` block, and the block's closing sentinel line is the last line of the entire message — nothing comes after it.

```handoff
OUTCOME: <done | blocked | plan-is-wrong | bad-dispatch>
plan: <plan path>
phase: <N>
agent_id: <your agent id, or: unknown>
files_changed: <path>, <path>   (or: none)
commit: <hash>   (or: none)
verification: <n> of <m> automated commands run, <k> exited 0
END-OF-REPORT
```

## Outcome tokens

Four tokens, and these are their preconditions:

- `done` — every automated-verification command for the phase ran and exited 0 with its output pasted, AND every `[NEW]`, `[MODIFY]`, and `[DELETE]` item and every listed edge case of the phase is complete.
- `blocked` — the implementer stopped deliberately and is resumable; `files_changed` lists everything it touched, which may legitimately be none.
- `plan-is-wrong` — the plan's own text must change before the phase can be done.
- `bad-dispatch` — the dispatch contains a reference that resolves to nothing.

`plan-is-wrong` and `bad-dispatch` are valid only if the tree holds no edit of that worker's for this phase, including any previous attempt.
