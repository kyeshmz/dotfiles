# AGENTS.md — editing `implementer.md`

The implementer executes exactly one phase of an existing plan against the working tree. It is
half of a two-part protocol; see `../planner/AGENTS.md` for the other half and `../AGENTS.md`
for rules that apply to every role.

## The contract is not in this file — do not put it back

Plan path, dispatch shape, return envelope, outcome tokens, and plan-file write ownership live
in `../skills/handoff-contract/SKILL.md`, preloaded into both agents via `skills:` frontmatter.

- **A contract change goes in the skill**, never here. If you are editing the `handoff` block,
  the token names, or the dispatch block list in this file, you are in the wrong file.
- What belongs here is implementer-*side* behavior on top of the contract: the ordered
  token-selection rules, pre-flight, the retry cap, halts, and the report body.
- Keep `skills: [handoff-contract]` and the instruction to read the skill from disk if it is not
  already in context.

## Invariants

- **`name: implementer`.** `/pipeline` and all three conductor lanes dispatch by this name.
  There is exactly one implementer and it declares no model — the engine is the caller's
  choice. Do not reintroduce a vendor-specific variant; that was removed deliberately.
- **The cold-context sentence stays at the top.** "The planner sees ONLY your final message"
  plus the ban on "see above". Without it, implementers write summaries that reference work the
  planner cannot see — a named, measured failure mode.
- **Token selection is an ORDERED list, first match wins.** This replaced an earlier partition
  on "have you edited anything", which made two tokens fit the same halt and routed the planner
  to opposite actions. If you add a token or a condition, re-check that every reachable halt
  maps to exactly one outcome, and that the planner has a distinct action for it. A token that
  triggers the same planner action as another should be merged away.
- **`plan-is-wrong` and `bad-dispatch` are valid only on a clean tree** for this phase. Both
  assert "nothing was applied"; the planner relies on that to re-dispatch safely.
- **`done` requires phase completeness, not just green commands.** Every `[NEW]`/`[MODIFY]`/
  `[DELETE]` item and every listed edge case must be implemented. Otherwise `done` and an
  admitted unimplemented item are simultaneously valid — a real defect found in review.
- **`blocked` is valid with `files_changed: none`.** Do not add a rule implying otherwise.
- **Two attempts per step, then stop.** Must stay consistent with the planner's 1 re-dispatch
  per phase and 2 replans per plan.
- **Both stop-boundaries stay.** Numeric halt conditions AND the explicit anti-premature-stop
  rule ("do NOT stop for milestones, significant progress, or session boundaries"). Remove
  either and you get the opposite failure: an agent that grinds forever, or one that declares
  partial victory at a narrative boundary.
- **Evidence is pasted, never characterized.** Keep the ✅/❌ pair. "Three type errors in the
  auth module" is a claim; the command, its exit code, and its output are evidence.
- **The ~400-word cap applies to prose only.** Pasted command output is explicitly exempt and
  must never be trimmed to fit. If you tighten the cap, keep that carve-out.
- **`END-OF-REPORT` is the last line of the entire message.** The planner parses for it and
  treats its absence as an unparseable return.

## Things that look like improvements and are not

- Letting the implementer spawn subagents. It must not decompose its own work; the planner owns
  decomposition. The definition says so explicitly — keep it.
- Letting it fix unrelated issues it notices. Those go under "Not done" as follow-ups.
- Letting it edit the plan to match what it did. The plan is the planner's; only the two
  sanctioned writes are allowed.
- Adding a "tick the box if you're confident" shortcut. A box is ticked only after running that
  exact command and pasting its output.
- Returning a diff or patch for someone else to apply. It edits files in the tree.

## After editing

```sh
# frontmatter intact, no model, skill still wired
grep -q '^name: implementer$' implementer.md && grep -q 'handoff-contract' implementer.md && ! grep -q '^model:' implementer.md && echo OK

# report scaffold survived
for s in 'What changed' 'Verification run' 'Deviations' 'Not done' 'END-OF-REPORT'; do
  grep -qF "$s" implementer.md || echo "LOST: $s"
done

# install
../sync.sh          # install + verify every role
../sync.sh --check  # verify only; non-zero exit on drift
```

Then read `../planner/AGENTS.md` and confirm nothing you changed contradicts it.
