---
description: Plan and implement with the planner agent driving implementers phase by phase, then review in parallel with the inspector plus optional security and performance consultants.
argument-hint: [--cross-review] [--secure] [--perf] [--no-review] <task description>
---

Run the following pipeline for this task: $ARGUMENTS

Engine-agnostic by construction. There is one agent per role and none of them declares a model — every definition inherits whatever engine the session is running. To change engines, pass a per-invocation `model` on the Agent call; never edit a definition and never write a model or vendor name into an agent prompt.

Flags (strip them from the task before passing it on):
- `--cross-review`: run a second `inspector` in Stage 2 with a different `model` than the first, for an independent second opinion. Also do this unprompted when the diff touches auth, payments, migrations, or concurrency.
- `--secure` / `--perf`: force the security or performance consultant on. See Stage 2 for when they run unprompted.
- `--no-review`: stop after Stage 1. For throwaway or exploratory work only.

Handoff contract: subagents see nothing from this conversation. Every agent prompt must be self-contained — objective, artifacts verbatim (plan, reports, findings), expected output format, and explicit boundaries. The planner enforces this on its own dispatches; you enforce it on the review agents.

## Stage 0 — Diagnose first, if the cause is unknown

If the task is "fix X" and nobody knows why X is happening, do not plan yet — launch `debug-consultant` with the symptom plus any issue id, stack trace, failing command, or time window. It is read-only and never fixes.

Feed its verdict into Stage 1:
- `DIAGNOSED` / `PARTIALLY_DIAGNOSED` — pass the hypothesis, its evidence, and its `Ruled out` section to the planner verbatim as the plan's starting evidence.
- `UNDETERMINED` / `CANNOT_REPRODUCE` — relay its `Next evidence` line and stop. Do not plan a speculative fix on an undetermined cause; that is how symptom suppression ships.

Skip Stage 0 when the cause is already known, or the task is a feature rather than a defect.

## Stage 1 — Plan and implement (planner agent)

Launch the `planner` agent with the task verbatim, plus any context from this conversation that bears on it (files already discussed, constraints the user stated, decisions already made).

The planner owns both planning and implementation: it writes one plan to `.plans/<task-slug>.md` and dispatches `implementer` phase by phase, verifying artifacts between phases. Do not dispatch implementers yourself.

It returns one of three things:

- **A declined task.** The planner returns a one-line instruction and writes no plan, because the change is too small to plan. Do the work yourself, then go to Stage 2 only if the diff warrants it.
- **A question.** The planner halts without a plan because a decision belongs to the user. Relay the question and stop; re-launch the planner with the answer.
- **A completed change.** Its final line reads `PLAN: <path>`. Read that plan file — you need it verbatim for Stage 2.

Relay a short summary to the user: goal, files touched, phases run, verification results, anything the planner escalated.

If the planner exhausted a budget (2 replans, or 1 re-dispatch of a phase) and escalated, stop and present the blocker with its evidence. Do not paper over it by implementing the remainder yourself.

## Stage 2 — Review in parallel

Launch these concurrently in one message. Each prompt must contain the original task, the plan verbatim, and the implementer reports from the planner's summary.

**Always:** `inspector` — correctness, plan conformance, independent re-verification. This is the gate.

**`security-consultant`** when `--secure` is set, or unprompted when the diff touches authentication, authorization, user input, file paths, queries, outbound requests, dependencies, secrets, or agent/tool wiring. Advisory only — a `CLEAN` verdict is not evidence the change is secure, and a `DEGRADED` verdict means its verification step failed, not that the change is fine.

**`performance-consultant`** when `--perf` is set, or unprompted when the task was about performance, or the diff adds database queries, loops over user-controlled collections, or request-path I/O. It never gates: `PERF_FINDINGS` are proposals, and its own definition forbids it from approving or rejecting.

**A second `inspector` on a different `model`** per `--cross-review`. Give it exactly the same prompt as the first; the only variable is the engine, otherwise you are comparing two different questions rather than two opinions.

Merge the results:
- A finding two reviewers report independently is top priority — but only when they were genuinely independent. Two `inspector` runs on the same model are one opinion; agreement between them is not corroboration.
- Deduplicate against the inspector — the consultants are told to stay in their lanes, so overlap usually means the finding is real.

## Gating

- **`inspector` BLOCKING findings** gate. So do **`security-consultant` findings**, which are all blocking by construction (it reports at most 5 and drops anything that fails its bar).
- Performance findings, inspector MINOR findings, and security non-blocking findings do not gate. Relay them as optional follow-ups; do not act on them unasked.

## Fix loop

Send blocking findings back to the **planner**, not to an implementer directly — the planner owns the plan file and the dispatch. Its prompt gets the findings verbatim plus the plan path, scoped to fixing only those findings. It will append a remediation phase and dispatch it. Then re-run Stage 2.

Track findings across rounds. Run at most 3 fix rounds, and stop early if the same finding survives two consecutive rounds, or a fix round introduces as many new blocking findings as it resolves. At that point present the unresolved findings, each agent's position, and your recommended decision. Escalation is the correct outcome there, not a failure.

## Rules the performance consultant emits

If it proposed rule artifacts (`.claude/rules/*.md`, `.semgrep/perf/*.yaml`, query-count assertions), show them to the user and ask before writing any of them. They are durable and they cost context on every future session — that is the user's call, not yours.

## Final report

End with: the inspector's verdict, the security verdict if it ran, every file changed, verification results, the plan path, and any nits or open questions. Do not commit unless the user asked for a commit, or the plan's Conventions block specified it.
