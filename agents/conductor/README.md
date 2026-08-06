# conductor

Three multi-agent workflows for [Microsoft Conductor](https://github.com/microsoft/conductor).

Every role that does real work is one of the `.md` definitions in `../`.
Nothing in these YAML files describes what a planner or an implementer or a
reviewer *is* — they name a role, and `agent-def.py` loads the definition off
disk. Edit `../planner.md` and every lane changes on the next run.

```sh
./run.sh light "add rate limiting to the API"     /path/to/repo
./run.sh max   "refactor the auth module"         /path/to/repo
./run.sh codex "port the parser to the new AST"   /path/to/repo
```

## The roles

| Role | Definition | Gates? |
|---|---|---|
| planner | `../planner/planner.md` | — |
| implementer | `../implementer/implementer.md` | — |
| inspector | `../inspector/inspector.md` | **yes** |
| security-consultant | `../security-consultant/security-consultant.md` | **yes** |
| performance-consultant | `../performance-consultant/performance-consultant.md` | never |

Resolution order is `<agents-dir>/<role>/<role>.md`, then the flat
`<agents-dir>/<role>.md`, then `~/.claude/agents/`. `run.sh` checks every role it will need before it
spends a token, because a missing definition would otherwise degrade the role
into a generic assistant — the one failure the `.md` files exist to prevent.

`../debug-consultant.md` is deliberately **not** wired in. In `/pipeline` it is a
Stage 0 role that runs only when the cause of a defect is unknown, and it is
allowed to end at `UNDETERMINED` — a trigger and an exit none of these lanes
model. Wiring it in would mean deciding, without a human, when a task is a
diagnosis rather than a build.

## The three lanes

**`light`** — one cold reviewer, up to two planner revisions.

```
baseline → preflight → plan ─→ review_1 ─┬─ approved ───────────────────→ gate
                    (planner) (Opus 5)   ├─ reject ──────────────────→ ✗
                                         └─ revise → revise_1 → review_2 ─┬─→ gate
                                                    (planner)   (Opus 5)  └─ revise_2 → gate
```

**`max`** — three independent reviewers, adjudicated by a fourth Opus 5.

```
baseline → preflight → plan → external_reviews ─→ opus_review → synthesizer ─┬─ approved → gate
                    (planner)  ├ independent      (Opus 5)      (Opus 5)     └─ revise → revise → gate
                               └ repo-grounded                                        (planner)
```

**`codex`** — one cold review, then a different vendor writes the code.

```
baseline → preflight → plan → plan_reviewer ─┬─ approved ──────→ gate
                    (planner)  (Opus 5)      └─ revise → revise → gate
```

All three then converge:

```
gate → implement ────────→ tests ──────────→ review_panel ────────→ validator → ledger
       planner dispatches  different model   inspector           Opus 5
       implementers,       from the          + security
       phase by phase      implementer       + performance
```

## Why it is shaped this way

**The planner plans and implements — in two invocations.** Its definition has
it write the plan *and* dispatch implementers phase by phase, handling
`blocked`, `plan-is-wrong`, resumes, and its own 2-replan / 1-re-dispatch
budgets. Re-implementing that loop in bash would fork the seam that
`planner.md` and `implementer.md` define between them. So the loop stays
inside the planner, and the split exists only so the review panel and the
human gate land between the halves.

**"Plan only" is a mechanism, not a request.** In `plan` and `revise` mode the
Agent tool is withheld from the planner's allowlist, so it *cannot* dispatch.
It is restored for `implement`.

**Reviewers are fresh.** `context.mode: explicit` means an agent sees only what
its `input:` list names. Without it Conductor's default (`accumulate`) hands
every prior agent's output to every later one, and the "fresh" reviewer would
be reading the planner's reasoning — which defeats the point of having it.
This is the single most load-bearing line in all three files.

**The synthesizer adjudicates; it does not rewrite the plan.** The plan file has
exactly one author. A second agent with write access to it would break the
ownership rule both `planner.md` and `implementer.md` depend on. So the
synthesizer emits a self-contained finding list and the planner revises
against it.

**The test author is a different model.** A model that just wrote the code
writes tests encoding the same misunderstanding. This is also the one role
with no `.md` definition, deliberately: an agent whose entire value is being a
different model from the implementer does not belong in a definition that
names neither.

**The validator judges the original task, not the plan.** The panel already
covered correctness, conformance, security, and performance, and the validator
is told not to re-derive their findings. It answers the one question none of
them was asked: does this solve the problem that was actually asked for? A
plan can be executed perfectly, pass every check, and still miss.

**In `max`, agreement is only evidence if the reviewers are actually
independent.** When antigravity is missing, the independent reviewer falls back
to Opus 5 — and the synthesizer is explicitly told
`independent_family_present: false` so it does not treat same-family agreement
as corroboration.

## Engines

An engine is *how* a definition runs, never *what* it says.

| Role | Engine | Default model |
|---|---|---|
| planner / implementer / panel | `claude-code` | frontmatter (`fable`, `opus`) |
| plan review / synthesis / validation | Conductor `claude` provider | `claude-opus-5` |
| tests | opencode (codex lane: codex) | `parley/openai/gpt-5.6-luna` |
| repo-grounded plan review (max) | opencode | `parley/openai/gpt-5.6-terra` |
| independent plan review (max) | antigravity → `claude -p` | `gemini-3-pro` → `claude-opus-5` |

`claude-code` is the default for definition-backed roles because it is the only
adapter with a real system-prompt channel (`--system-prompt-file`) and a tool
allowlist (`--allowed-tools`). The other adapters prepend the definition to the
prompt instead: same text, weaker separation.

**The plan engine has no fallback.** Conductor's `claude` provider reaches tools
only through MCP, so it cannot read files or run commands — a `type: agent`
step can review a plan but cannot write one, execute one, or inspect a diff.
Preflight stops the run rather than degrading into something the definitions do
not describe.

Conductor has no opencode or codex provider (`copilot`, `claude`,
`claude-agent-sdk`, `hermes`, `openai-agents`), so those run as `type: script`
steps.

## Fallbacks

`preflight` probes each engine once, up front, and the workflow routes on the
result rather than discovering an outage halfway through:

| Unavailable | Result |
|---|---|
| plan engine | run stops — no fallback, by design |
| `codex` binary, codex lane | run stops; the planner refuses to substitute engines |
| test model | test pass skipped; the panel still runs |
| antigravity | Opus 5 via `claude -p`, flagged `independent_family: false` |

Quota is **per-model**: one model can be capped while another works. Probes are
cheap, because an unavailable model is rejected before tokens are billed.

## Token accounting

Two sources, reconciled by `scripts/token-report.py`:

- **Conductor's `UsageTracker`** for `type: agent` steps. It is *displayed*,
  never written to the result JSON, so `run.sh` passes `--log-file` and the
  report scrapes the table. Drop that flag and that half silently reads as zero.
- **Each engine adapter** normalizes its own usage into
  `$RUN_DIR/tokens/<label>.json`, which is what keeps `token-report.py` free of
  per-engine logic.

Counter semantics differ per engine and getting them wrong is silent: opencode
emits per-step counters (**sum**), codex emits cumulative ones (**max**). See
`scripts/engines/README.md`.

`--phase before` snapshots usage; `--phase after` diffs it and prints the
ledger. The headline number is the per-step sum (direct, scoped to this run);
the account delta is a cross-check, since it also moves if unrelated activity
runs concurrently.

Thinking tokens are never capped: `max_tokens` is deliberately unset because on
the Anthropic path it covers thinking and answer combined, and every Conductor
agent runs at `reasoning: {effort: max}`.

## Layout

```
run.sh                     entry point for all three lanes
workflows/
  light.yaml               one reviewer, ≤2 planner revisions
  max.yaml                 three reviewers + synthesizer
  plan-review-implement.yaml   the codex lane
scripts/
  agent-def.py             role name → definition body, tools, model
  agent-plan.sh            the planner: plan | revise | implement
  agent-review.sh          inspector + the two consultants, concurrent
  agent-tests.sh           test authoring, different model
  agent-run.sh             engine dispatcher
  engines/*.sh             one adapter per engine
  preflight.sh             probe engines, decide fallbacks
  external-reviews.sh      independent + repo-grounded plan reviews (max)
  gemini-review.sh         antigravity → claude -p fallback
  token-report.py          before/after ledger
runs/                      artifacts, gitignored
```

`agent-fanout.sh`, `agent-implement.sh`, and `agent-worker.sh` are **superseded**
and unreferenced — each carries a banner saying so. They were the parallel
task-queue path, where the planner emitted independent work items fanned out to
concurrent workers. `planner.md` specifies the opposite: 3-7 sequential phases,
one implementer, every phase boundary leaving the tree compiling. They are also
not runnable as written, since they call an `oc-run.sh` that no longer exists.

## Known constraints

- **Conductor rejects `script` steps inside `for_each` and `parallel:` groups.**
  That is why the review panel's three agents and the two external plan reviews
  each run as background jobs inside one step. It costs wall-clock, not
  independence — that comes from `context.mode: explicit` and from each agent
  getting its own process and its own prompt.
- **The `claude` provider has no file tools.** It reaches tools only over MCP,
  and no MCP servers are configured here. Every role that must read the repo,
  write a plan, or run a command is a script step on the `claude-code` engine
  for that reason.
- **antigravity is not installed here**, so the independent reviewer always
  falls back to Opus 5. Its invocation (`antigravity --model M --prompt P`) is a
  reasonable guess and unverified; check it against the real CLI before relying
  on that path.
- **`opencode/*` (OpenCode Zen) has no credit** on this machine — use
  `parley/*`, which is authenticated and verified working.
- The `⚠ may not run on all paths` warnings on validate are expected: the static
  checker does not see through the `{% if ... is defined %}` guards in `output:`.

## Verified

- All three workflows pass `conductor validate`; `light` passes `--dry-run`.
- `agent-def.py` resolves all five roles, strips frontmatter, maps model
  aliases, and drops withheld tools.
- `agent-plan.sh` in `plan` mode, against a scratch repo: the planner **declined**
  a one-sentence change (correct per its triage rule) and the script reported
  `declined: true`; a genuinely multi-file task produced `.plans/<slug>.md`,
  detected via the `PLAN:` line, with phases counted.
- `agent-review.sh`: all three reviewers ran concurrently, returned parseable
  verdicts, and emitted token files. Gating computed correctly.
- Verdict-token parsing is unit-tested against decorated and prose-embedded
  forms — the performance consultant emitted `` `PERF_CLEAN` `` with backticks
  on the first real run, which the strict matcher missed.
- The `--system-prompt-file` path is confirmed to replace the system prompt.
- **Not yet run:** any lane end-to-end, `implement` mode, and the `max` and
  `codex` lanes at all.
