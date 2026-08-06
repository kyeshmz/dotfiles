# agents

Six coding-agent role definitions, the contract that binds two of them, the command that drives
them, and the research they were built from.

This tree is the single source of truth. `~/.claude` is a build output — never edit it directly.

One directory per role. Each holds the definition plus an `AGENTS.md` naming the invariants an
editor must preserve — read that before changing the definition next to it.

```
sync.sh                                installs into ~/.claude, then verifies
AGENTS.md                              shared editing rules for every role
planner/          planner.md           plan + orchestrate
implementer/      implementer.md       execute one phase
inspector/        inspector.md         correctness review — the gate
security-consultant/                   security review
performance-consultant/                performance review
debug-consultant/                      diagnose, never fix
skills/handoff-contract/SKILL.md       the planner↔implementer contract
skills/writing-pull-requests/SKILL.md  standalone: strict PR title/body rules
commands/pipeline.md                   the slash command that drives them
```

## Sync

```sh
./sync.sh            # install agents + skills + commands, then verify
./sync.sh --check    # verify only; non-zero exit on drift
./sync.sh --dry-run
```

The live layout is **flat** (`~/.claude/agents/<role>.md`); only this source tree uses
subdirectories. `sync.sh` will not copy the per-role `AGENTS.md` files, and fails if one turns
up under `~/.claude/agents` — that directory is scanned recursively for subagent definitions, so
a file without agent frontmatter is at best ignored and at worst parsed as a broken agent.

### What this makes automatic, and what it does not

| | Loaded into every session? |
|---|---|
| `~/.claude/rules/*.md` | **Yes** — always in context. Currently just `context7.md`. |
| `~/.claude/agents/*.md` | No. *Available* in every project; used only when Claude delegates to one (matching its `description`) or you name it explicitly. |
| `~/.claude/skills/handoff-contract/` | No. Preloaded only into `planner` and `implementer`, via their `skills:` frontmatter. |
| `~/.claude/skills/writing-pull-requests/` | No. Available in every session; loaded when Claude is about to draft or edit a PR title/body (matched by description), not tied to the pipeline roles. |
| `~/.claude/commands/pipeline.md` | No. Only when you type `/pipeline`. |
| this repo's `AGENTS.md` files | No. Only when an agent edits files in the matching directory, in this repo. |

Syncing makes the roles **available everywhere**, not **active by default**. To make the pipeline
the default path for non-trivial work rather than something you invoke, that instruction has to
live in an always-loaded file — `~/.claude/CLAUDE.md` (does not exist yet) or a new
`~/.claude/rules/*.md`.

**No definition declares a model.** Every one inherits whatever engine the session is
running. To change engines, pass a per-invocation `model` on the Agent call, set
`CLAUDE_CODE_SUBAGENT_MODEL`, or launch the whole run on a different engine — never edit a
definition. This is what makes the set engine-agnostic, and it is why there is exactly one
implementer rather than one per vendor.

## How they fit together

`/pipeline` drives them:

```
Stage 0   debug-consultant     only when the cause is unknown; diagnosis feeds the plan

Stage 1   planner ──> writes .plans/<task-slug>.md
                 └──> dispatches an implementer, phase by phase, verifying between phases

Stage 2   inspector  +  security-consultant  +  performance-consultant   (parallel)
          (gates)      (gates)                 (advisory, never gates)

Stage 3   blocking findings ──> back to the planner, which appends a remediation phase
```

The planner declines small work rather than planning it. If it can describe the diff in one
sentence, it hands the sentence back and writes no plan. The debug consultant is allowed to
end at `UNDETERMINED`, and the pipeline stops there rather than planning a speculative fix.

## Engine-agnostic

Roles are fixed; the engine is chosen per run, not per role.

There is one definition per role, none declares a model, and no description or dispatch may
name a model or a vendor. The planner dispatches `implementer` and never assumes what is
behind it. If an engine's CLI is missing or unauthenticated, the planner relays that up and
stops rather than silently substituting.

The consequence worth knowing: you can no longer mix engines *within* one run. Previously a
Claude-run wrapper agent shelled out to the `codex` CLI so Codex could write code inside a
Claude session. Without that wrapper, the engine is a session-level choice — conductor's
`codex` lane now runs the whole pipeline on the codex engine via `--plan-engine codex`.

**Repo conventions live in `AGENTS.md`.** It is the cross-tool standard ([agents.md](https://agents.md/)) —
plain markdown, no required fields, nested files resolve closest-wins, and ~20 agent tools read
it natively. Claude Code reads `CLAUDE.md`, not `AGENTS.md`, so bridge them rather than
maintaining two:

```markdown
@AGENTS.md

## Claude Code
<Claude-specific additions below the import>
```

or `ln -s AGENTS.md CLAUDE.md` when there is nothing Claude-specific to add.

The planner reads `AGENTS.md` (nearest first), then `CLAUDE.md`, `.claude/rules/`,
`.cursor/rules/`, and `.github/copilot-instructions.md` when it builds a plan's Conventions
block — and copies what it finds in **verbatim**, because loaded is not followed. The
performance consultant writes new rules to the most portable artifact the repo already uses,
preferring a nested `AGENTS.md` over a Claude-only rules file.

`conductor/` runs the same definitions unattended, with a plan review panel and a human gate
inserted between the planner's two halves. It reads these `.md` files directly — see
`conductor/README.md`.

## The seam

The planner and implementer are two halves of one protocol. The protocol is defined **once**, in
`skills/handoff-contract/SKILL.md`, and preloaded into both agents via `skills:` frontmatter —
the two sides drifted when each carried its own copy. Consumers that strip frontmatter do not
preload it — conductor's `agent-def.py` passes each definition body verbatim as a system
prompt — and rely on the pointer in each body naming the on-disk path
`~/.claude/skills/handoff-contract/SKILL.md`.

| | |
|---|---|
| Plan path | `.plans/<task-slug>.md`, one per task, inside the repo |
| Dispatch blocks | What this phase must achieve / Read this first / Files you own / Already on disk / Conventions that apply / Verification you must run / Out of scope |
| Return envelope | fenced ` ```handoff ` block, first line `OUTCOME:`, last line `END-OF-REPORT` |
| Outcome tokens | `done`, `blocked`, `plan-is-wrong`, `bad-dispatch` |
| Write ownership | implementer writes exactly two things in the plan file: its own phase's automated-verification checkboxes, and an appended `## Execution log` entry |

**A contract change goes in the skill, not in either definition.** What stays in each definition
is that side's behavior on top of the contract. Budgets: at most 2 replans per plan, 1
re-dispatch per phase, 2 attempts per step — the planner's and implementer's must stay
consistent with each other.

## Research

Everything in `research/` is generated. Start with `00`, then the brief for whichever agent
you are editing.

| File | What it is |
|---|---|
| `00-claude-code-subagent-spec.md` | Verified mechanical constraints from the Claude Code docs. **Beats the briefs wherever they disagree** — it corrects two claims they got wrong. |
| `01-planner-implementer-brief.md` | Sweep 1 design brief: official guidance, framework patterns, failure literature, spec-driven dev, real prompts |
| `01a-planner-sources-and-prompts.md` | Sweep 1 sources + verbatim prompt excerpts |
| `02-planner-implementer-brief-evidence.md` | Sweep 2 design brief: papers, forums, GitHub, production blogs |
| `02a-evidence-appraisal.md` | What is actually supported vs merely popular. The **cargo cult** section is a ban list. |
| `02b-evidence-sources-and-prompts.md` | Sweep 2 sources + verbatim prompt excerpts |
| `03-security-consultant-brief.md` | Security agent design brief |
| `03a-security-appraisal.md` | False-positive control mechanisms, ranked by evidence |
| `03b-security-sources-and-prompts.md` | Security sources + prompt excerpts |
| `04-performance-consultant-brief.md` | Performance agent design brief, including the rules-synthesis contract |
| `04a-performance-appraisal.md` | Measurement bar, folklore ban list, what makes a rule stick |
| `04b-performance-sources-and-prompts.md` | Performance sources + prompt excerpts |
| `05-example-plan-from-dogfooding.md` | A real plan the planner wrote, kept as a worked example of the format |
| `06-debug-consultant-brief.md` | Debug agent design brief: evidence ladder, symptom playbook, MCP protocol |
| `06a-debug-appraisal.md` | What stops an agent confabulating a root cause; why confidence scores are banned |
| `06b-debug-sources-and-prompts.md` | Debug sources + prompt excerpts |

Caveats worth knowing before you trust a number in there:

- **reddit.com blocked the crawler.** Reddit material only appears where HN reposted it, so
  "practitioner consensus" in sweep 2 is HN- and GitHub-weighted.
- Some figures could not be traced to a primary source and are flagged as such in the
  appraisals. The briefs mark confidence per principle; believe those labels.
- The briefs claimed CLAUDE.md does not reach subagents. **That is false** — see `00`. The
  claim survives only as one about adherence, not delivery.

## Design decisions worth not re-litigating

Each of these was a contradiction between the two research sweeps, resolved deliberately:

- **The planner keeps bounded reports, not transcripts** — justified by context budget, *not*
  by quality. The one controlled study (Handoff Debt, 2,172 runs) found raw traces beat
  curated summaries for a successor. Hence: evidence is quoted verbatim and is exempt from the
  length cap; only prose is capped.
- **The implementer ticks the checkboxes**, not the planner — parent-held state dies to
  compaction, subagent truncation, and blank-context retries; file state survives all three.
  Accepted failure mode: an implementer can tick a box for a command it misread. The
  compensating control is that the planner verifies via `git diff <base_sha>..` and never
  treats a checkbox as evidence.
- **The planner grades artifacts and exit codes, never plan compliance.** A 16,991-trajectory
  study found compliance and success can correlate *inversely*. A deviation that passes
  verification is accepted, and is not a replan trigger.
- **Four outcome tokens, not six.** Each earns its place by triggering a distinct planner
  action. Merged tokens are worse than useless — they get ignored.
- **The plan is advisory and both files say so.** Nothing enforces it at the model level. The
  three things that substitute: re-reading the plan at fixed points, literal commands inside
  the checkboxes, and artifact-level acceptance.
- **No agent emits a confidence number.** LLM confidence in code settings is measurably
  uncorrelated with correctness (ECE 0.09–0.73; only 52% of completions rated >90% confident
  actually passed). The debug consultant grades on a named evidence ladder instead, and the
  security consultant gates on an eight-item bar rather than a self-scored 0–100. The
  inspector keeps its 0–100 threshold because it is re-running verification it can check.
- **Two places where prose is the only control**, and the debug consultant says so out loud:
  PostHog exposes a single `exec` tool per region multiplexing ~100 read *and* write domains
  behind one string argument, so a denylist cannot separate them; and Playwright's interaction
  tools stay enabled because toggling a live condition is the only route to a confirmed
  frontend diagnosis. Everywhere else, enforcement is a missing tool.

## Regenerating

The workflow scripts are under
`~/.claude/projects/<project>/<session>/workflows/scripts/`. Re-run one with
`Workflow({scriptPath, resumeFromRunId})` — unchanged agent calls replay from cache, so
editing a late stage does not re-pay for the research.

The previous generation of `planner.md` and `implementer.md` is in `.backup-agents-*/`.
