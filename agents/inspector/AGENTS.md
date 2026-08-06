# AGENTS.md — editing `inspector.md`

The inspector is the correctness gate. It reviews a completed implementation against its plan,
independently re-runs verification, and returns the verdict `/pipeline` branches on. See
`../AGENTS.md` for rules that apply to every role.

This is the oldest and shortest definition here, and it predates the research sweeps. Its
brevity is not an oversight — resist padding it out to match its siblings.

## Invariants

- **`name: inspector`.** `/pipeline` and all three conductor lanes dispatch by this name, and
  it is the only agent whose verdict gates the pipeline.
- **`tools: Read, Glob, Grep, Bash`** — no `Write`, no `Edit`. It reports; others fix. It runs
  builds and tests via `Bash`, which is the point: a reviewer that cannot re-run verification
  can only take the implementer's word.
- **Three verdict tokens, exactly:** `APPROVED`, `APPROVED_WITH_NITS`, `NEEDS_FIXES`, on their
  own line. `NEEDS_FIXES` only if at least one BLOCKING finding exists. Adding or renaming one
  means updating `../../dot_claude/commands/pipeline.md` and every conductor lane in the same
  change.
- **Keep the noise-control block.** A reviewer told to find gaps will report some even when the
  work is sound — that is the documented failure mode this block exists to prevent. Specifically
  keep: only correctness/requirement-gaps/unverifiable-claims count; the 0–100 confidence rating
  with the **80 threshold**; and the BLOCKING vs MINOR split.
- **The confidence threshold is deliberate here and only here.** Sibling reviewers ban
  self-scored confidence because it is uncalibrated. The inspector keeps it because it is
  grading work it independently re-ran — it has an external check behind the number. Do not
  "harmonize" this with the other reviewers by removing it, and do not copy it into them.
- **"No scenario, no finding."** Every suspected bug needs a concrete failing scenario: inputs
  or state → wrong behavior. This is the single strongest filter in the file.
- **Re-running verification is mandatory, not optional.** Keep "any claim in the report you
  cannot reproduce is itself a finding" — it converts the implementer's report from testimony
  into a checkable claim.

## Staying in its lane

Security, performance, and debugging have their own agents that run in parallel on the same
diff. The inspector covers correctness, edge cases, and plan conformance. Do not add security
checklists or performance heuristics here — duplicated findings double the noise for no signal,
and the sibling definitions explicitly defer correctness back to this one.

## Things that look like improvements and are not

- Lowering the confidence threshold to catch more. The threshold exists because the marginal
  finding below it is noise.
- Adding style, naming, or maintainability findings. Explicitly out of scope.
- Letting it fix what it finds. The read-only tool list is the enforcement; the prose just
  explains it.

## After editing

```sh
grep -q '^name: inspector$' inspector.md && ! grep -q '^model:' inspector.md && echo OK
for t in APPROVED APPROVED_WITH_NITS NEEDS_FIXES; do grep -qF "$t" inspector.md || echo "LOST: $t"; done
grep -qF 'No scenario, no finding' inspector.md || echo "LOST: the scenario rule"

../sync.sh          # install + verify every role
../sync.sh --check  # verify only; non-zero exit on drift
```

If you changed a verdict token, grep for it across `../../dot_claude/commands/` and
`../conductor/workflows/` before you stop.
