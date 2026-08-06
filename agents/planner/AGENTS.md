# AGENTS.md — editing `planner.md`

The planner writes one plan to `.plans/<task-slug>.md` and dispatches the implementer phase by
phase. It is half of a two-part protocol; see `../implementer/AGENTS.md` for the other half and
`../AGENTS.md` for rules that apply to every role.

## The contract is not in this file — do not put it back

Plan path, dispatch shape, return envelope, outcome tokens, and plan-file write ownership live
in `../skills/handoff-contract/SKILL.md`, preloaded into both agents via `skills:` frontmatter.
That is deliberate: the two sides drifted when each carried its own copy.

- **A contract change goes in the skill**, never in this file. If you find yourself editing the
  dispatch template or the `handoff` envelope here, you are editing the wrong file. Naming a
  contract element in order to *react* to it is fine and expected — the return-handling table
  refers to a missing `OUTCOME` line or `END-OF-REPORT` sentinel because classifying a malformed
  return is planner-side behavior. Reproducing the template is not.
- What belongs here is planner-*side* behavior on top of the contract: `base_sha`, overwrite-in-
  place on revision, archiving a finished plan, and the fact that the planner ticks nothing.
- Keep `skills: [handoff-contract]` in the frontmatter, and keep the sentence telling the agent
  to read the skill from disk if it is not already in context. Preloading is not guaranteed in
  every runtime.

## Invariants

- **`name: planner`.** `/pipeline` and all three conductor lanes dispatch by this name.
- **`tools: Read, Grep, Glob, Bash, Write, Agent`.** Each earns its place: `Write` is the plan
  file only, `Agent` is dispatch. Conductor deliberately withholds `Agent` (via `--drop-tools`)
  to split planning from execution so a human gate lands between them — do not make dispatch
  structurally required, or that lane breaks.
- **The write scope is one path.** The body must keep "The ONLY file you may create or edit is
  the plan"; the shell allowlist; the ban on redirects, heredocs, temp files, and writing pipes;
  and the carve-out permitting test/build/lint/typecheck runs. That carve-out is load-bearing —
  a planner that cannot run the test suite cannot validate feasibility, which is the highest-
  value thing it does.
- **The triage gate stays first**, before any exploration, and keeps all six decline conditions.
  A planner that plans small changes anyway is a net cost. The gate must precede exploration;
  moving it later means the cost is already paid.
- **Phase cap 3–7**, driven by file regions and compile integrity, never by requirement count.
- **Budgets: 2 replans per plan, 1 re-dispatch per phase.** These must match the implementer's
  2-attempts-per-step. Changing one without the other produces either an agent that gives up
  while the other is still retrying, or an unbounded loop.
- **Prescriptive about WHAT and WHERE, permissive about HOW.** Keep the anchor-string rule for
  prose artifacts — mandating the exact substring that must appear and must no longer appear is
  the only way a prose edit is verifiable.
- **Acceptance is on artifacts and exit codes, never plan compliance.** Do not add a rule that
  rejects a phase for deviating; a 16,991-trajectory study found compliance can correlate
  *inversely* with success. A deviation that passes verification is accepted.
- **Keep the `## Never` list.** Every entry is a named failure, not a style preference: banned
  referential phrases, line numbers in plans, effort estimates, alternatives-considered
  sections, self-review by opinion, unfalsifiable acceptance criteria, `plan-v2.md`.
- **Keep the final `PLAN: <path>` line.** Nothing else discovers the plan file.

## Things that look like improvements and are not

- Adding an alternatives-considered section. A cold implementer treats an alternative as a live
  option and may build the rejected branch.
- Letting the planner self-review its plan for correctness. Self-correction without external
  feedback does not improve accuracy and often degrades it. Plan self-check is permitted only
  where it terminates in an external comparison: does this path exist, does this symbol exist,
  does every phase end in a runnable command.
- Adding a confidence score to a plan. There is nothing to calibrate it against.
- Adding a per-phase review pass. The review-pass clause is deliberately once-per-change and
  gated on a halt surface.

## After editing

```sh
# frontmatter intact, no model, skill still wired
head -8 planner.md
grep -q '^name: planner$' planner.md && grep -q 'handoff-contract' planner.md && ! grep -q '^model:' planner.md && echo OK

# the dispatch template did not leak back in — it lives in the skill
! grep -q 'Execute Phase <N>' planner.md && echo "contract still in the skill"

# install and re-check the callers
../sync.sh          # install + verify every role
../sync.sh --check  # verify only; non-zero exit on drift
```

Then read `../implementer/AGENTS.md` and confirm nothing you changed contradicts it.
