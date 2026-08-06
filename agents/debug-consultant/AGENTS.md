# AGENTS.md — editing `debug-consultant.md`

Diagnoses a defect whose cause is unknown, pulling evidence from the repo, the runtime, and
whichever observability MCP servers are reachable. It never fixes. See `../AGENTS.md` for rules
that apply to every role.

Design brief: `../research/06-debug-consultant-brief.md`. Evidence: `../research/06a-debug-appraisal.md`.

Unlike its siblings this one is not tied to a diff, and it is Stage 0 of `/pipeline` rather than
part of the review fan-out.

## The one thing to understand before editing

**Calibrate to an 11% base rate.** On the closest measured analogue — 335 real enterprise
failures with full telemetry — the best agent configuration identified the root cause 11.34% of
the time; hand-labelled correctness on real cloud incidents was 35–39%. The failure mode is a
fluent, confident, wrong causal narrative, which costs the reader their time *and* their trust
budget. `UNDETERMINED` is a frequent, valid, successful outcome and the file must keep saying so.

Every edit that makes the agent more likely to produce an answer makes it worse.

## Invariants

- **`name: debug-consultant`.** Dispatched by name from `/pipeline` Stage 0.
- **`disallowedTools`, not `tools`.** Deliberate: it needs broad MCP access, so it inherits
  everything and subtracts the write primitives. Switching to an allowlist would freeze an
  inventory the file explicitly says must be discovered at runtime, and would silently drop
  servers added later. Keep the denylist entries in `mcp__<server>__*` glob form.
- **`maxTurns: 60` is coupled to stopping rule 4.** That rule says "at turn 30 with no
  reproduction and no discriminating observation, stop investigating." Without a denominator the
  rule silently never fires. If you change one, change the other in the same edit.
- **No confidence numbers, anywhere.** Not percentages, not probabilities, not 0–1 scores. LLM
  confidence in code settings is measurably uncorrelated with correctness. The evidence ladder
  replaces it. Percentages *measured from tool output* are evidence and are explicitly allowed —
  keep that carve-out, or the no-numbers rule suppresses the negative-control figures the
  CORROBORATED tier requires.
- **Six ladder tiers, and PROVEN stays hard.** It requires bidirectional causal control the
  agent observed itself: remove the cause and the symptom goes, restore it and the symptom
  returns. `causal_test` is a per-hypothesis field, never one global block — otherwise one
  toggle can be made to serve three ranked claims.
- **The ceiling clamp runs AFTER tier selection**, taking the lowest that fires. That ordering
  is what makes the ladder non-negotiable rather than advisory.
- **Hypotheses are written BEFORE gathering evidence for them**, each with a falsifier committed
  in advance. This ordering is the entire guard against confirmation bias — a falsifier written
  afterwards is chosen to be one that happens not to have been met. Do not reorder the loop.
- **Empty means not observed, never did not happen.** Keep the five-way classification of a
  zero-row result; only `genuinely-absent-in-a-source-that-would-have-shown-it` may support a
  ruled-out claim.
- **Deferred tools need `ToolSearch` before use.** Keep the instruction and the load cap.
- **`Ruled out` and `Sources consulted` are mandatory sections**, including when everything
  worked. They are what make an undetermined result useful instead of empty.
- **Five verdict tokens:** `DIAGNOSED`, `PARTIALLY_DIAGNOSED`, `UNDETERMINED`,
  `CANNOT_REPRODUCE`, `LIKELY_ALREADY_FIXED`. The triage short-path drops sections but never
  drops the token line.
- **It never emits a patch, a diff, or fix code** — "catching yourself drafting one is the
  signal you skipped the investigation."

## Two places where prose is the only control

Both are documented in the file and must stay documented — the honesty is the point.

1. **PostHog is one `exec` tool per region** multiplexing ~100 read *and* write domains behind a
   single string argument. A denylist cannot separate them: denying the tool removes the primary
   evidence surface, keeping it grants every write. The pre-call domain check is the only guard.
2. **Playwright interaction tools stay enabled** because toggling a live condition is the only
   route to a confirmed browser-side diagnosis. Navigate, snapshot, read, evaluate-to-read, and
   toggle exactly one suspected condition — never submit a form or mutate authenticated state.

If you ever find a way to enforce either mechanically, do that and delete the prose.

## Things that look like improvements and are not

- Adding a "now critique your reasoning" pass. A reflection turn with no new observation reliably
  converts a hedge into a confidently defended answer. Re-entry requires new evidence.
- Letting it propose a fix alongside the diagnosis. A plausible patch launders an unproven causal
  claim into a settled one.
- Trusting an upstream AI root-cause output. It is a hypothesis tagged `[retrieved]`.
- Adding severity labels (P0/P1/critical) or a fixed-depth template like Five Whys.

## After editing

```sh
grep -q '^name: debug-consultant$' debug-consultant.md && ! grep -q '^model:' debug-consultant.md && echo OK
for t in DIAGNOSED PARTIALLY_DIAGNOSED UNDETERMINED CANNOT_REPRODUCE LIKELY_ALREADY_FIXED; do
  grep -qF "$t" debug-consultant.md || echo "LOST: $t"; done
grep -qE '^maxTurns: [0-9]+' debug-consultant.md || echo "LOST: maxTurns (stopping rule 4 breaks)"
grep -qF 'Ruled out' debug-consultant.md || echo "LOST: the ruled-out section"

../sync.sh          # install + verify every role
../sync.sh --check  # verify only; non-zero exit on drift
```
