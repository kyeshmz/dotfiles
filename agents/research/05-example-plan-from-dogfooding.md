<!--
HISTORICAL ARTIFACT — kept as a worked example of the plan format, not as live work.

This plan was written by the planner agent itself during the dogfooding phase of
`wf_66491966-ebe`, when it was instantiated under its own definition and asked to review the
implementer definition. It found 12 seam defects and emitted this plan to fix them. Those
fixes were then folded into the final files directly, so this plan was never dispatched.

It refers to `code-planner` / `code-implementer` and to `agents/drafts/`; both were renamed
(to `planner` / `implementer`) and the drafts directory was consolidated before install. Read
it for the SHAPE — how a decision-complete plan reads when the repo has no build, test, or
lint command and the verification has to be built out of grep assertions instead.
-->

---
task: planner-implementer-seam-fixes
plan_path: .plans/planner-implementer-seam-fixes.md
base_sha: fbe563e2d180b56250db8e142cc342754ec9d47f
---

# The code-implementer definition can execute a dispatch from code-planner without hitting a contradiction, and every halt it can reach maps to exactly one outcome token.

## Context

`code-planner` (planner-orchestrator.md) and `code-implementer` (implementer.md) form a two-stage pipeline whose only durable channel is the plan file. A review of the implementer against the planner's obligations found twelve seam defects. Five are load-bearing: the dispatch's owned-files rule forbids the plan-file writes the implementer is required to make (fires on every phase); a resume dispatch makes the implementer misreport its own `[NEW]` file as `plan-is-wrong` with a false `files_changed: none`; `done` is satisfiable with plan items left undone; two tokens fit the same halt and route the planner to opposite actions; and the deviation protocol licenses renaming paths and exported symbols that later phases import.

The fix is entirely textual — normative sentences added to or removed from two agent definition files. No code, no dependencies, no schema. The approach: close the write-scope contradiction first because it fires on every dispatch and its fix spans both files; then convert the outcome tokens from an ambiguous partition into an ordered decision procedure; then teach pre-flight and the deviation protocol which pre-existing state is legitimate.

## Conventions in force

Copied verbatim from this repository. Do not go looking for these anywhere else.

- Build: none. This is a chezmoi-managed dotfiles repo. `ls package.json Makefile justfile .pre-commit-config.yaml` returns four "No such file or directory" errors; there is no `.github/workflows`.
- Test: none. Verification for this task is the grep assertions written into each phase below. They are the test suite.
- Lint: none.
- Typecheck: none.
- File layout: agent definitions in progress live in `agents/drafts/`. `agents/drafts/security-consultant.md` and `agents/drafts/performance-consultant.md` are the two siblings from the same research batch.
- Agent-definition format: YAML frontmatter delimited by `---` on line 1, carrying `name`, `description`, `tools`, `model`, followed by a markdown body. Both files under change already conform; do not restructure the frontmatter.
- Forbidden here: do not renumber, reorder, retitle, or delete an existing `##` section in either file. Every change in this plan is an insertion into, or a replacement inside, a section that already exists.
- Forbidden here: do not use angle-bracket pseudo-XML tags as section delimiters in either file body.
- Commits: do not commit. Leave all changes unstaged. `agents/` is currently untracked (`git status --porcelain` shows `?? agents/`) and the user has not asked for a commit.
- Shell is zsh. `grep -qF`, `test "$(head -n 1 F)" = '---'`, and `for b in ...; do ... done` loops were confirmed working in this checkout.

## Evidence

### Verified

- `git rev-parse HEAD` -> `fbe563e2d180b56250db8e142cc342754ec9d47f`
- `git rev-parse --show-toplevel` -> `/Users/kyeshmz/Documents/personal/dotfiles`
- `git status --porcelain` -> ` M Brewfile`, `?? .DS_Store`, `?? agents/`, `?? dot_asdf/.DS_Store`, `?? dot_claude/`, `?? dot_config/.DS_Store`. The entire `agents/` tree is untracked.
- `ls -la agents/drafts/` -> `performance-consultant.md` (21086 bytes), `security-consultant.md` (20197 bytes). Neither `planner-orchestrator.md` nor `implementer.md` is present at the time of writing.
- `ls package.json Makefile justfile .pre-commit-config.yaml .chezmoiroot .chezmoi.toml.tmpl` -> only `.chezmoi.toml.tmpl` exists. `ls -a .github/workflows` -> "No such file or directory". There is no build, test, or lint entry point in this repository.
- `wc -l dot_claude/agents/*.md` -> `implementer.md` 26 lines, `planner.md` 33 lines. I opened both: `dot_claude/agents/implementer.md` declares `name: implementer` / `model: opus` and `dot_claude/agents/planner.md` declares `name: planner` / `model: fable`. These are the PREVIOUS generation and are NOT the files this plan changes. Do not edit them.
- Both files under change were read in full as text (the full body of each is the input to this review), which is why every quoted string below is exact.
- Command forms proven in this checkout: `for b in "name:" "description:"; do grep -qF "$b" "$A" && grep -qF "$b" "$B" || { echo "MISSING: $b"; exit 1; }; done` -> `loop OK exit=0`; `test "$(head -n 1 "$A")" = '---'` -> `frontmatter head test OK`.

### Unverified

- Both target files are expected at `agents/drafts/planner-orchestrator.md` and `agents/drafts/implementer.md`, by analogy with the two sibling drafts from the same research batch. Neither existed when this plan was written; the caller holds them. Check it by running `ls -la agents/drafts/planner-orchestrator.md agents/drafts/implementer.md` before dispatching Phase 1. If either path differs, correct the two paths in this plan's phase headings before dispatch — do not dispatch against a path that does not resolve.

## Existing code to reuse

- `agents/drafts/security-consultant.md` -> frontmatter block — the house shape for an agent definition in this repo (`---` on line 1, `name` / `description` / `tools` / `model`). Match it; do not invent a new frontmatter layout.
- `agents/research/02a-evidence-appraisal.md` -> the "Cargo cult" section — the ban list for this repo's agent definitions. Nothing added by this plan may reintroduce an item from it.

## Operational definitions

- **Anchor string**: a literal substring that a phase requires to appear verbatim in the edited file. Each one is what its phase's `grep -qF` assertion matches. The surrounding sentence is the implementer's to write; the anchor is not.
- **Seam**: a place where an obligation the planner definition states about the implementer must be matched by wording in the implementer definition. A seam holds when both files can be read independently and produce the same behavior.
- **Load-bearing dispatch block**: a `##` block in the dispatch prompt whose absence genuinely prevents execution, as opposed to one that is absent because it would have been empty.

## Assumptions

- Do not commit — chosen because `agents/` is wholly untracked, the user did not ask for a commit, and leaving the diff unstaged keeps it reviewable in one `git diff` against a clean baseline.
- Fixes land in both files only where the seam requires both sides; every other fix is implementer-side only — chosen because a one-sided edit to a two-sided contract is the defect class this plan exists to remove.
- Anchor strings are mandated verbatim, but the sentences around them are not — chosen because for a specification file the normative sentence is the interface, while its phrasing and placement are internals.
- The twelve findings collapse into three phases rather than one edit per finding — chosen because Phases 2 and 3 rewrite overlapping regions of the same file, and separate dispatches would collide.

---

## Phase 1 — Close the write-scope contradiction

At the end of this phase, an implementer can tick a checkbox and append to the execution log without violating the dispatch's owned-files rule, and both files say so in matching words.

### [MODIFY] `agents/drafts/implementer.md`

- Current: section `## 2. Scope` opens `Only create, edit, or delete files in the owned-files list for this phase. If you believe you must touch a file outside that list, stop and return `OUTCOME: blocked` naming the file and why.` The contract bullet **Write ownership** separately grants two writes into the plan file, which is never in the owned-files list. Section `## 7. Reporting` never instructs the `## Execution log` append that the contract permits.
- Change: rewrite the opening of `## 2. Scope` so the owned-files rule carries the plan-file carve-out and states that those two writes are never a reason to return `blocked`, and that the plan file is listed in `files_changed` alongside the source files. Add to `## 7. Reporting` an ordered final step that appends the report's `What changed`, `Verification run`, and `Deviations` content as one entry at the end of `## Execution log`, performed after verification and immediately before emitting the final message, never rewriting an earlier entry.
- Anchor strings, verbatim: `plus the plan file, where you may tick` and `as one entry at the end of`
- Must no longer appear: `Only create, edit, or delete files in the owned-files list for this phase. If you believe`
- Preserve: the rest of `## 2. Scope` — the no-while-I'm-here rule, the one-phase-only rule, and the no-TODOs rule. Preserve the `## 7. Reporting` template's section order and its ~400-word prose cap.
- Edge cases: `the phase's owned-files list is empty` -> the plan-file carve-out still applies; `the plan's Conventions block says to commit` -> the plan file is staged with the source files, since the implementer changed it; `the implementer halts before running any verification command` -> it still appends its Execution log entry before reporting, recording what it did and did not run.

### [MODIFY] `agents/drafts/planner-orchestrator.md`

- Current: the dispatch template in `## 5. Dispatching` reads `Do not create, edit, or delete any file outside this list.` under `## Files you own in this phase`.
- Change: extend that sentence with the same carve-out, so the dispatch the implementer actually receives contains the exception rather than relying on the implementer's role definition to supply it.
- Anchor string, verbatim: `except the plan file, where you may tick`
- Preserve: the dispatch template's block order and every other line of it. Do not add a block.
- Edge cases: `the dispatch is a resume` -> the carve-out sentence is unchanged and still present.

#### Automated verification
- [ ] Implementer carries the scope carve-out: `grep -qF 'plus the plan file, where you may tick' agents/drafts/implementer.md`
- [ ] The contradictory sentence is gone: `! grep -qF 'Only create, edit, or delete files in the owned-files list for this phase. If you believe' agents/drafts/implementer.md`
- [ ] The Execution-log append is an instruction, not just a permission: `test "$(grep -cF '## Execution log' agents/drafts/implementer.md)" -ge 2 && grep -qF 'as one entry at the end of' agents/drafts/implementer.md`
- [ ] Planner dispatch template mirrors the carve-out: `grep -qF 'except the plan file, where you may tick' agents/drafts/planner-orchestrator.md`
- [ ] Both files are still valid agent definitions: `for f in agents/drafts/implementer.md agents/drafts/planner-orchestrator.md; do test "$(head -n 1 $f)" = '---' && test "$(grep -c '^name: ' $f)" -eq 1 || { echo "BAD FRONTMATTER: $f"; exit 1; }; done`

---

## Phase 2 — Make the outcome tokens a decision procedure

At the end of this phase, every halt an implementer can reach maps to exactly one token, and `done` cannot be returned over an incomplete phase.

### [MODIFY] `agents/drafts/implementer.md`

- Current: `## 1. Pre-flight` closes with `Both tokens are valid only while you have edited nothing; once you have edited any file, use `OUTCOME: blocked` and state exactly what you already changed.` This partitions the token space on "have you edited anything", which contradicts `## 5. Deviations and halts` — that section mandates `blocked` for four situations that occur before any edit. Separately, the `done` precondition in `## 7. Reporting` is stated purely in terms of verification commands, while the report template's `**Not done**` block invites `<unchecked plan item, and why>`, so `done` and an admitted unimplemented plan item are simultaneously valid. Separately, `bad-dispatch` is defined as `missing a required block` without naming which blocks are required.
- Change: replace the edited-nothing partition with an ordered decision list, applied top to bottom, first match wins: (1) a reference in the dispatch that cannot be resolved from the prompt, the plan, or the repository -> `bad-dispatch`; (2) the plan itself must change before the phase can be done at all — a named path or symbol is absent, a `[NEW]` path already exists that is not yours, or the phase is impossible as written no matter what the planner replies -> `plan-is-wrong`; (3) you stopped deliberately and a planner answer or redirection would let you continue -> `blocked`, whether or not you have edited anything; (4) otherwise -> `done`. State explicitly that `blocked` is correct with `files_changed: none`. Add to the `done` precondition that every `[NEW]`, `[MODIFY]`, and `[DELETE]` item in the phase is complete and every `<condition> -> <expected behavior>` edge case the phase lists is implemented; if any is not, the token is `blocked` and the item goes in `Not done`, which may otherwise contain only follow-ups never asked for. Name the load-bearing dispatch blocks — `## What this phase must achieve`, `## Files you own in this phase`, `## Verification you must run` — and state that the remaining blocks may legitimately be absent when they would be empty, so `bad-dispatch` is reserved for an unresolvable reference and never for an absent optional block.
- Anchor strings, verbatim: `item in your phase is complete`, `is correct with files_changed: none`, and `never for an absent optional block`
- Must no longer appear: `Both tokens are valid only while you have edited nothing`
- Preserve: the four token names exactly as spelled, the fenced ` ```handoff ` envelope, the `plan` / `phase` / `agent_id` / `files_changed` / `commit` / `verification` field names, and `END-OF-REPORT` as the block's last line. The planner's dispatch table keys off all of these and none may be renamed.
- Edge cases: `the phase requires a dependency the plan did not name, nothing edited` -> `blocked` by rule 3, because a planner reply naming the dependency unblocks it; `a [MODIFY] path in the phase does not exist` -> `plan-is-wrong` by rule 2, because no planner reply fixes it without changing the plan; `an owned file carries an unexplained third-party change` -> `blocked` by rule 3, reporting the verbatim `git status --porcelain` line; `two attempts on the same step failed` -> `blocked`, with `files_changed` listing everything touched; `all verification passed but one [MODIFY] item was left undone` -> `blocked`, not `done`.

#### Automated verification
- [ ] The ambiguous partition is gone: `! grep -qF 'Both tokens are valid only while you have edited nothing' agents/drafts/implementer.md`
- [ ] `done` requires phase completeness: `grep -qF 'item in your phase is complete' agents/drafts/implementer.md`
- [ ] `blocked` permits an empty file list: `grep -qF 'is correct with files_changed: none' agents/drafts/implementer.md`
- [ ] `bad-dispatch` is bounded: `grep -qF 'never for an absent optional block' agents/drafts/implementer.md`
- [ ] Token names and envelope survive unrenamed: `for t in 'OUTCOME: <done | blocked | plan-is-wrong | bad-dispatch>' 'END-OF-REPORT' 'files_changed:' 'verification:'; do grep -qF "$t" agents/drafts/implementer.md || { echo "LOST: $t"; exit 1; }; done`
- [ ] Frontmatter intact: `test "$(head -n 1 agents/drafts/implementer.md)" = '---' && test "$(grep -c '^name: ' agents/drafts/implementer.md)" -eq 1`

---

## Phase 3 — Teach pre-flight and the deviation protocol which state is legitimate

At the end of this phase, a resume or recovery dispatch does not trip the mismatch checks, and the deviation protocol cannot rename something a later phase imports.

### [MODIFY] `agents/drafts/implementer.md`

- Current: `## 1. Pre-flight` step 2 states `A path tagged `[NEW]` must NOT already exist — if it does, that is a mismatch and is also `plan-is-wrong`.` with no resume exception, so on a resume the worker's own created file is reported as a plan defect. Step 3 carves out only `On a resume dispatch` for pre-existing changes, so a fresh dispatch of a recovery phase halts on state the dispatch's `## Already on disk from earlier phases` block already declared. `## 5. Deviations and halts` says to `proceed with the adjustment unless the step touches a halt surface`, with no protection for path and symbol names, and never defines what "touch" means for a halt surface. `## 4. Verification` says to run the commands `exactly as written in the plan` while the dispatch carries its own `## Verification you must run` list, with no stated precedence. `## 3. Doing the work` says to re-read the plan `before any edit to a file the current phase did not name`, describing a procedure for an action section 2 forbids, and says to restate concepts `in your working output`, a term the file never defines and that collides with the report's prose cap.
- Change: (a) add the resume exception to step 2 — a `[NEW]` path you created in your own previous attempt is expected; continue from it. (b) add to step 3 that changes listed under `## Already on disk from earlier phases` are expected regardless of which phase or worker produced them. (c) add to `## 5` that a repo-relative path or an exported symbol name the plan states is not a deviable detail, because a later phase may import it; if one is wrong that is `plan-is-wrong` before the first edit and `blocked` after it, and deviation applies to internals only. (d) define halt-surface "touch" as your change altering the behavior of that surface, not the file you are editing merely mentioning it, and state that when the plan's `## Halt surfaces` names a surface and your phase's own text states the intended behavior on it, that is authorization to proceed with the assumption noted. (e) add to `## 4` that when the dispatch's `## Verification you must run` list and the phase's `#### Automated verification` block disagree, run the union of both and report `<n> of <m>` against the plan's count, never the dispatch's. (f) in `## 3`, change the third re-read trigger to `immediately before you emit your report`, and replace `in your working output` with wording that places the restatement in reasoning before the first edit and explicitly not in the final report.
- Anchor strings, verbatim: `you created in your previous attempt is expected`, `regardless of which phase or worker produced them`, `is not a deviable detail`, `not that the file you are editing mentions it`, and `run the union of both`
- Must no longer appear: `before any edit to a file the current phase did not name` and `in your working output`
- Preserve: the three pre-flight steps as three numbered steps, the `Step / Expected / Found / Why it matters / Adjustment` deviation block field names, the halt list's existing surfaces, and the two-attempt retry cap.
- Edge cases: `resume dispatch, [NEW] file exists and is the worker's own` -> continue from it, no mismatch; `fresh dispatch, [NEW] file exists and is not named under Already on disk` -> `plan-is-wrong`; `the plan's exported symbol name is unavailable because it collides with an existing export` -> `plan-is-wrong` before the first edit, `blocked` after; `the edit is in a file containing an authorize() call but does not change authorization behavior` -> proceed, note the assumption; `the dispatch lists two commands and the phase lists three` -> run all three, report `3 of 3`.

#### Automated verification
- [ ] Resume exception present: `grep -qF 'you created in your previous attempt is expected' agents/drafts/implementer.md`
- [ ] Recovery-dispatch exception present: `grep -qF 'regardless of which phase or worker produced them' agents/drafts/implementer.md`
- [ ] Names are non-deviable: `grep -qF 'is not a deviable detail' agents/drafts/implementer.md`
- [ ] Halt-surface "touch" is defined: `grep -qF 'not that the file you are editing mentions it' agents/drafts/implementer.md`
- [ ] Verification precedence stated: `grep -qF 'run the union of both' agents/drafts/implementer.md`
- [ ] Dead procedures removed: `! grep -qF 'before any edit to a file the current phase did not name' agents/drafts/implementer.md && ! grep -qF 'in your working output' agents/drafts/implementer.md`
- [ ] Deviation block fields survive: `for t in 'Step:' 'Expected:' 'Found:' 'Why it matters:' 'Adjustment:'; do grep -qF "$t" agents/drafts/implementer.md || { echo "LOST: $t"; exit 1; }; done`
- [ ] Frontmatter intact: `test "$(head -n 1 agents/drafts/implementer.md)" = '---' && test "$(grep -c '^name: ' agents/drafts/implementer.md)" -eq 1`

#### Manual verification
- [ ] Read `## 1. Pre-flight` and `## 7. Reporting` end to end as a cold implementer would and confirm the ordered token rules and the pre-flight exceptions do not contradict each other after all three phases have landed.

---

## Out of scope

- `dot_claude/agents/implementer.md` and `dot_claude/agents/planner.md` — the previous generation, a different pair, not touched by this plan.
- `agents/drafts/security-consultant.md` and `agents/drafts/performance-consultant.md`.
- Anything under `agents/research/` — these are read-only source material.
- The planner's triage rules, replan budgets, dispatch-table rows, and review-pass clause. The only planner-side edit in this plan is the one sentence in Phase 1.
- Adding, removing, or renaming an outcome token. The four-token set is fixed.
- Installing either file to `dot_claude/agents/` or running chezmoi.

## Halt surfaces

Stop and report instead of proceeding if the work would touch:
- authentication, authorization, tokens, PII, CORS, or session management
- a destructive schema change or a data migration
- an external API contract
- any file under `private_dot_ssh/`, `.chezmoi.toml.tmpl`, or `dot_gitconfig`
- the outcome-token names, the ` ```handoff ` envelope, or the `END-OF-REPORT` sentinel — the planner's dispatch table parses all three and this plan does not change them

## Definition of done

- [ ] Every automated-verification command in every phase has been run and exited 0
- [ ] The seam holds end to end: `for b in "What this phase must achieve" "Read this first" "Files you own in this phase" "Already on disk from earlier phases" "Conventions that apply here" "Verification you must run" "Out of scope for this dispatch" "Answer to your blocker" "Evidence from your previous attempt"; do grep -qF "$b" agents/drafts/implementer.md && grep -qF "$b" agents/drafts/planner-orchestrator.md || { echo "SEAM BROKEN: $b"; exit 1; }; done` exits 0
- [ ] No file outside the paths named in this plan was changed: `git status --porcelain` shows no entry other than the pre-existing ` M Brewfile`, `?? .DS_Store`, `?? .plans/`, `?? agents/`, `?? dot_asdf/.DS_Store`, `?? dot_claude/`, `?? dot_config/.DS_Store`

---

## Execution log

<Implementer appends here, newest last. Planner does not write in this section.>

---
Section ownership: everything above `## Execution log` is written by the planner and is READ-ONLY to the implementer, except the `#### Automated verification` checkboxes, which the implementer ticks after running the command and pasting its output. `#### Manual verification` boxes are ticked only by a human. Omit any section entirely when it would be empty — never write "None."
