# AGENTS.md — editing `performance-consultant.md`

Reviews a completed diff under a hard measurement gate, and distills recurring defects into
durable rules and detectors the implementer follows later. Runs in parallel with the inspector.
See `../AGENTS.md` for rules that apply to every role.

Design brief: `../research/04-performance-consultant-brief.md`. Evidence, including the
folklore ban list: `../research/04a-performance-appraisal.md`.

## The one thing to understand before editing

**An unmeasured optimization is a presumed regression, not a neutral suggestion.** Roughly half
of a frontier model's optimization patches measure *slower* than the code they replace, and
localization — deciding which function actually carries the time — is the step models are worst
at. Every gate in this file exists because the failure mode is a stream of plausible,
unmeasured suggestions with negative expected value.

The tempting edit is to relax the measurement gate so the agent can "still be useful" when no
profiler exists. Do not. The file already handles that case: it declares `NO MEASUREMENT
AVAILABLE`, emits hypotheses labelled as such, and names the harness the repo needs — which is
usually the highest-leverage finding available.

## Invariants

- **`name: performance-consultant`.** Dispatched by name from `/pipeline` and two lanes.
- **`tools: Read, Glob, Grep, Bash, Write, Edit`.** `Write`/`Edit` exist ONLY for rule artifacts.
  The body scopes them; keep that scoping explicit and keep application code, tests, config, and
  CI report-only. This is the one reviewer that may write, so the scope sentence is doing real
  work.
- **The measurement gate runs before any code is read**, and probes for a real harness. Keep the
  `NO MEASUREMENT AVAILABLE` banner as the literal first line when nothing runs.
- **The four evidence tags are a closed enum**, exactly one per finding, evidence inline:
  `[MEASURED-TOOL]`, `[MEASURED-DELTA]`, `[ARGUED]`, `[HYPOTHESIS]`. A finding that cannot carry
  one is deleted, and deletions are counted. Do not add a fifth tag — the enum's value is that
  each maps to a different permitted claim.
- **Keep the explicit may-claim / may-never-claim lists.** Without a measurement the agent may
  claim round-trip counts, traced complexity, unbounded result sets, index leading-column
  correctness, blocking I/O on an async path, and a missing harness — and may never claim a
  function is hot, that a change will be faster, any ms or % figure, or anything about
  allocation, GC, or locality.
- **The statistical protocol is numeric and stays numeric:** ≥10 runs (20–30 under 10%), ≥1
  discarded warm-up, median plus dispersion, declared cache state, machine and load, verbatim
  repro command. Sub-100ms means count work instead of timing it. Shared CI runners make
  wall-clock deltas inadmissible at any size.
- **The Amdahl floor (5%) and the payoff arithmetic** must stay printed, not implied.
- **The "Never emit these" list is the folklore ban.** Every entry is advice LLMs reproduce
  reflexively with no measurement behind it. Do not prune it for length; it is the file's
  immune system.
- **The reward-hack check runs on every proposed change.** A benchmark that got faster is not
  evidence the code got faster.
- **It never gates.** Verdict tokens `PERF_FINDINGS`, `PERF_NO_TOOLING`, `PERF_INVESTIGATE`,
  `PERF_CLEAN`, and the file must keep "You do not approve or reject the change."

## The rules ladder

This is the part most likely to be edited carelessly.

- **The default answer to "should I write a rule?" is NO.** A bad finding costs one PR; a bad
  rule costs every future PR and occupies context permanently. All five conditions —
  OBSERVED, RECURRENT, MEASURED, CHECKABLE, EXPIRABLE — must hold and be stated in the artifact.
- **Portability order matters and was chosen deliberately:** a nested `AGENTS.md` in the
  directory the rule applies to, then root `AGENTS.md`, then `.claude/rules/<topic>.md` with
  `paths:` globs when glob precision is genuinely needed. `AGENTS.md` is read natively by ~20
  agent tools and resolves closest-wins, so a rule there reaches whichever engine implements
  next; `.claude/rules/` reaches only Claude. Do not reorder these back.
- **Match what the repo already uses.** Never introduce a second instructions system alongside
  an existing one.
- **Deterministic enforcement beats prose.** The ladder ends in Semgrep rules with tests, query-
  count assertions, and CI budgets for deterministic metrics only — never a wall-clock
  percentage gate on a shared runner.
- **The caps are numeric and enforced:** ≤5 always-on rules per repo, ≤10 per scoped file, any
  always-loaded instructions file under 200 lines, `SKILL.md` under 500. Past a cap, name the
  rule you delete or merge. Delta updates only — never regenerate a rules file wholesale.
- **Do not assert an unverified format detail.** If a frontmatter field or path is not confirmed
  in `../research/00-claude-code-subagent-spec.md`, phrase it conditionally or drop it.

## After editing

```sh
grep -q '^name: performance-consultant$' performance-consultant.md && ! grep -q '^model:' performance-consultant.md && echo OK
for t in PERF_FINDINGS PERF_NO_TOOLING PERF_INVESTIGATE PERF_CLEAN; do
  grep -qF "$t" performance-consultant.md || echo "LOST: $t"; done
for t in MEASURED-TOOL MEASURED-DELTA ARGUED HYPOTHESIS; do
  grep -qF "$t" performance-consultant.md || echo "LOST tag: $t"; done
grep -qF 'NO MEASUREMENT AVAILABLE' performance-consultant.md || echo "LOST: the gate banner"

../sync.sh          # install + verify every role
../sync.sh --check  # verify only; non-zero exit on drift
```
