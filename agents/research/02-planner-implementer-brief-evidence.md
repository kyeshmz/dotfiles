# Planner & Implementer Agent Design Brief — Sweep 2 (Evidence-Weighted)

Synthesized from four sweeps — arXiv/ACL/ICLR/NeurIPS papers, practitioner forums (HN threads and comments, GitHub issues; **note: reddit.com blocked the crawler, so Reddit material appears only where HN reposted it**), raw GitHub prompt artifacts, and production engineering blogs — then filtered through an adversarial source appraiser that separated benchmarked claims from popular repetition. Run: `wf_71a772d1-270`, 6 agents, ~788K tokens, 233 tool calls.

## Principles

- **The implementer starts with zero conversation history; the plan must be executable with the conversation deleted.**
  - *Applies to:* both
  - *Why:* Aider's shipping code sets the editor's cur_messages=[], done_messages=[], map_tokens=0. Amp and Claude Code Agent Teams both state it as a product contract. Handoff Debt (2,172 runs): repo-only handoffs cost 20-59% more successor events and 42-63% more prompt tokens.
  - *Confidence:* well-established
  - *Concrete implication:* Planner agent.md ends with a self-check: 'Reread the plan with this conversation mentally deleted. Any phrase resolving to nothing (the file we looked at, as discussed, the approach above) must be rewritten as a literal path, symbol, or command.' Implementer agent.md: 'The plan file plus the repository are your only sources of intent.'
- **A plan step no command can check is not a step. Every phase carries literal verification commands, split from what only a human can judge.**
  - *Applies to:* both
  - *Why:* Agentless ablation makes validation the largest single contributor: majority voting 25.67% -> +regression tests 27.00% -> +reproduction tests 32.00%. MAST puts 23.5% of 1600+ annotated failures in verification/termination. HumanLayer, Antigravity, ship-mate and Traycer independently converged on the automated/manual split with the command inside the checkbox.
  - *Confidence:* well-established
  - *Concrete implication:* Plan template requires per-phase '#### Automated Verification' with the literal command inside each checkbox (- [ ] Type checking passes: npm run typecheck) and '#### Manual Verification' for human-eyeball items. Implementer agent.md: 'Paste the command and its actual output. Never check a box on judgment alone.'
- **Decide whether the task needs a plan at all before planning. A bad or padded plan is worse than no plan.**
  - *Applies to:* planner
  - *Why:* The 16,991-trajectory plan-compliance study found a subpar plan hurts more than no plan, and that adding sensible-looking extra phases (early regression tests) degraded DeepSeek-V3. ETH Zurich AGENTbench: LLM-generated repo context files cut success ~3% while raising cost 20-23%. Anthropic, Cursor, Traycer and Antigravity all ship an explicit skip-planning escape hatch.
  - *Confidence:* well-established
  - *Concrete implication:* Planner agent.md opens with a triage gate: 'If you could describe the diff in one sentence, do not write a plan; return the one-line instruction. Plan only when the change spans multiple files, the approach is uncertain, or the code is unfamiliar.' Plus a pruning test: 'For each line ask, would removing this cause a mistake? If not, cut it.' Plus a ban on inventing phases for thoroughness.
- **Name exact file paths and edit locations. Localization is the plan's highest-value content.**
  - *Applies to:* planner
  - *Why:* Agentless: hierarchical localization puts the ground-truth file in context 81.67% of the time vs 47.00% for direct localization, a 34.7pt gap. CodeR loses 8pts (22%->14%) with fault localization removed. Every serious artifact converges here; spec-kit explicitly rejects '- [ ] T001 [US1] Create model' as wrong for missing the path.
  - *Confidence:* well-established
  - *Concrete implication:* Plan template uses per-file headings tagged with the operation: '### [MODIFY] src/auth/session.ts', '### [NEW] ...', '### [DELETE] ...'. Planner may not emit a step without a path. Exception clause required: 'For a change that repeats a pattern across many files, describe the pattern once and list 3-5 representative paths; do not enumerate every file.'
- **Verification is external. No agent certifies its own output, and the planner never reviews its own plan by opinion.**
  - *Applies to:* both
  - *Why:* Huang et al. (ICLR 2024): intrinsic self-correction without external feedback does not improve and often degrades accuracy. PlanBench/o1: 97.8% on standard Blocksworld collapses to 52.8% on the obfuscated variant and cannot detect unsolvable instances, so model confidence in a plan is uninformative.
  - *Confidence:* well-established
  - *Concrete implication:* Planner agent.md forbids the sentence 'I have reviewed this plan and it is correct'; the only permitted plan self-check is one that terminates in an external comparison (does this path exist, does this symbol exist, does this requirement have a task, does this trace against a concrete case from the issue produce the stated output). Implementer agent.md forbids reporting 'verified' without pasted command output.
- **Capability restriction holds the role boundary, not prose. The planner is read-only, enforced twice.**
  - *Applies to:* planner
  - *Why:* Roo Code ships Orchestrator with groups: [] (no read, edit, command or MCP tools). Anthropic shipped delegate mode as a product feature precisely because, per its own troubleshooting docs, 'the lead starts implementing tasks itself instead of waiting'. A vendor shipping a mode rather than a prompt line is direct evidence prose failed. One practitioner tried four prompt-based mechanisms across 11 production agents; all four were ignored.
  - *Confidence:* well-established
  - *Concrete implication:* Planner frontmatter ships a tools allowlist excluding Edit/Write/NotebookEdit and the delegation tool. The body additionally names the shell escape hatches: no redirect operators (>, >>, |), no heredocs, no temp files including /tmp, no mkdir/touch/rm/cp/mv/git add/git commit/npm install; permitted bash verbs enumerated (ls, git status, git log, git diff, find, cat, head, tail). The plan file is the only writable path.
- **The plan is a file in the repo with a deterministic, task-derived name, and the implementer writes progress back into it.**
  - *Applies to:* both
  - *Why:* It is the only mitigation that survives the three mechanical orchestrator failures: silent subagent truncation (harness kills the loop mid-task and reports 'completed' with no marker), compaction amnesia (lead loses its team and its own role constraint after four compactions), and blank-context retries after quota errors that redo finished work. HumanLayer, Agent Teams, ship-mate, Antigravity and spec-kit all implement it. Countervailing failure: stale plan files get re-surfaced for unrelated tasks (7+ confirmations), fixed only by deletion.
  - *Confidence:* well-established
  - *Concrete implication:* Planner writes to one path per task, e.g. .plans/<task-slug>.md, inside the repo. Implementer agent.md: 'Check off automated-verification boxes in the plan file as you complete them, and append your outcome block to the plan file before reporting.' Both files carry a retirement rule: 'When the task is done and merged, delete or archive the plan file. Never resume a plan file for a different task.'
- **Restate every load-bearing convention inside the plan/dispatch text. Do not rely on CLAUDE.md, agent-definition bodies, or hooks reaching the implementer.**
  - *Applies to:* planner
  - *Why:* The strongest practitioner finding in the corpus: a heavy production user with 11 custom agents documented four propagation mechanisms (blocks at the top of all 11 agent MDs, Rule #1 in CLAUDE.md, an InstructionsLoaded hook, memory instructions) and reports all four failed, concluding 'Agent definition MDs and CLAUDE.md are effectively decorative for sub-agent behavior'. Corroborated by forensics over 296 subagent sessions with zero memories persisted and enumerated violations (wrong git identity, retry loops against a forbidden service).
  - *Confidence:* well-established
  - *Concrete implication:* Plan template requires a 'Conventions in force' block copied literally, not referenced: build command, test command, lint command, file/naming conventions that apply, forbidden patterns, commit/identity rules. Planner agent.md: 'Copy the rules the implementer needs into the plan verbatim. Do not write see CLAUDE.md.'
- **Decompose by information boundary and context economics, never by job title. Writes stay single-threaded.**
  - *Applies to:* planner
  - *Why:* Anthropic reports role decomposition made 'subagents spend more tokens on coordination than on actual work'. Google Research + MIT (180 configs, 4 benchmarks): every multi-agent variant degraded the sequential PlanCraft benchmark by 39-70%, and independent fan-out amplified errors 17.2x vs 4.4x centralized. Cognition after a year in production: multi-agent works 'when writes stay single-threaded and the additional agents contribute intelligence rather than actions'. Seven role-shaped planners produced internally consistent, mutually contradictory specs neither could see.
  - *Confidence:* well-established
  - *Concrete implication:* Planner agent.md carries an admission test for any delegation: 'Delegate only when the input is small, the work is large, the output is small, and the file set is disjoint from every other in-flight unit.' Plus an explicit prohibition: 'Never split one unit of work into planner/coder/tester/reviewer agents. Those are phases, not agents.' Plus: 'Two units may never name the same file. If a file is needed by two units, sequence them or own that edit yourself.'
- **The orchestrator needs an explicit restraint clause with the cost stated, because prompts bias toward spawning.**
  - *Applies to:* planner
  - *Why:* Measured spawn floor: 27,403 tokens for a default headless subagent, ~22k of it built-in tool schemas, vs 1,965 with tools: [] frontmatter. A third-party proxy benchmark found fan-outs cost 2.6x-5.9x metered input tokens for the same small task and were slower in wall-clock (2m15s sequential vs 17m for five subagents). Unrestrained selection produced ~13 agents for a contained CSS/TSX task and ~857,688 subagent tokens.
  - *Confidence:* well-established
  - *Concrete implication:* Planner agent.md includes Anthropic's restraint block nearly verbatim: subagents multiply cost and time; do the work inline when it is small and bounded; do not fan out on a single small task; do not spawn a subagent to review or double-check work you can verify inline; if you delegate, do not redo its work; brief once precisely rather than launch, wait and re-brief.
- **A system-prompt plan is advisory. Reinject it periodically rather than stating it once.**
  - *Applies to:* implementer
  - *Why:* The 16,991-trajectory study states outright that 'the plan is only advisory: it is included in the system prompt, but the scaffold's execution engine provides no mechanism to enforce it', measures models skipping phases (GPT-5 mini routinely skips reproduction), sees compliance drop ~13% on SWE-bench Pro, and finds the compliance-success correlation can invert per model. Its measured mitigation: reintroducing the plan every five steps improved success across all four models tested.
  - *Confidence:* well-established
  - *Concrete implication:* Implementer agent.md: 'Re-read the plan file before starting each phase, after any failed verification command, and before any edit that was not named in the current phase. Restate the current phase's success criteria in your own output before you edit.'
- **Give the implementer a structured deviation protocol instead of letting it silently skip or improvise, and validate the plan against the tree before the first edit.**
  - *Applies to:* implementer
  - *Why:* Plans are written against a snapshot and reality drifts; the choice is between undetectable divergence and an auditable escalation. Four independent implementations define the format (ship-mate, HumanLayer, Claude Code's worker prompt, wshobson). MAST supplies the frequencies of the unguarded version: step repetition 15.7%, unaware of termination conditions 12.4%, disobey task specification 11.8%. CodePlan is the cleanest context-matched evidence that plans must be re-derived from the code (5/7 repos pass build+correctness vs 0/7 for context-matched baselines).
  - *Confidence:* well-established
  - *Concrete implication:* Implementer agent.md mandates a pre-flight: 'Before the first edit, confirm every path the plan references exists and every named symbol is where the plan says. Report mismatches before editing.' And a fixed block: 'Step N / Expected / Found / Why it matters / Proposed adjustment / Proceeding with the adjustment unless instructed otherwise.' With named halt surfaces that convert it into a hard stop: auth, tokens, PII, CORS, sessions, destructive schema change, external API contract change.
- **State termination and escalation explicitly, including a retry cap. Models cannot recognize when they are stuck.**
  - *Applies to:* both
  - *Why:* MAST: step repetition 15.7%, unaware of termination conditions 12.4%, premature termination 6.2%. PlanBench shows o1 cannot reliably recognize unsolvable instances even at 97.8% on solvable ones, so 'stuck' has to be defined externally. Claude Code's worker prompt encodes the cap directly.
  - *Confidence:* well-established
  - *Concrete implication:* Plan template requires a 'Definition of Done' stated purely as command outcomes. Implementer agent.md: 'Do not retry the same failed approach more than once. After two failed attempts on the same step, stop and emit a blocked report rather than trying a third variation.' Planner agent.md forbids 'keep going until done' as a termination condition.
- **Pass validation evidence across the handoff, not just intent, and quote it rather than paraphrasing.**
  - *Applies to:* both
  - *Why:* In the one controlled handoff experiment, the largest resolve-rate gains (+12-19pts) occurred at handoff points immediately after a failed test, precisely where validation evidence exists. The same experiment is uncomfortable for aggressive summarization: raw traces improved resolve rate 6-15pts while curated structured notes managed only 1-10pts, often not statistically significant, at comparable token savings.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Plan template needs an 'Evidence' block: what the planner actually ran, the verbatim output or error, what was ruled out, and what remains uncertain. Implementer report contract requires verbatim failing command text and error output, not a summary of it. Both agent.md files must say: keep the named fields, but quote the raw evidence inside them rather than compressing it away.
- **Write the negative scope explicitly. Out of Scope is load-bearing, not decoration.**
  - *Applies to:* both
  - *Why:* Implementers reliably expand scope, and four independent artifacts carry a dedicated section for it (HumanLayer 'What We're NOT Doing', ship-mate 'Out of Scope', wshobson's task template, Claude Code's worker prompt). Anthropic separately documents the over-engineering shape it produces: extra abstraction layers, defensive code, tests for cases that cannot happen.
  - *Confidence:* well-established
  - *Concrete implication:* Plan template requires '## Out of Scope' with concrete named items, and per-unit 'Owned Files' when there is more than one unit. Implementer agent.md: 'Implement only what the plan specifies. No while-I'm-here changes. Note improvements you spot as follow-ups in your report; do not implement them. Do not add error handling for scenarios that cannot happen.'
- **Resolve open questions before emitting the plan; the artifact contains no question marks.**
  - *Applies to:* planner
  - *Why:* An unresolved question in a plan becomes a silent implementer guess. HumanLayer makes it a hard stop ('No Open Questions in Final Plan: if you encounter open questions, STOP'), ship-mate names five checkable escalation triggers and halts ('Do not guess'), spec-kit errors on unresolved clarifications, Claude Code requires questions be asked before ExitPlanMode.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Planner agent.md: 'The final plan contains no open questions. Only ask the human what code investigation cannot answer. If a genuine decision belongs to the human (external API contract change, destructive schema change, auth/security model change, scope exceeding the request, insufficient information), write one clear question and halt without writing a plan.'
- **Point the implementer at existing code to reuse, with paths, before proposing anything new.**
  - *Applies to:* planner
  - *Why:* The most common bad output of an unresearched planner is a plan that reinvents something already in the repo. Claude Code's plan mode makes reuse-hunting an explicit planner obligation in two phases; Traycer forbids assuming a library is available and requires looking at existing components first. HumanLayer's paired anecdote is that the researched plan 'fixed the problem in the best place' and was merged while the unresearched one was not.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Plan template requires an 'Existing code to reuse' section listing file path plus symbol name for each. Planner agent.md: 'Search for existing functions, utilities and patterns that can be reused before proposing new code, and cite them with paths in the plan.'
- **Size phases at pull-request granularity: each phase leaves the tree compiling and existing tests green.**
  - *Applies to:* planner
  - *Why:* Too-fine steps produce coordination overhead and orphaned code; too-coarse steps are unverifiable. Traycer's rule is the sharpest test available ('treat each phase like a well-scoped pull request' that 'always leaves the codebase compiling and all tests green'; if an API's return type changes, update all consumers in the same phase). Kiro forbids hanging or orphaned code. MapCoder's sweep shows returns saturating after ~5 units (84.8% -> 93.9% -> 94.2%); PlanBench shows plan reliability collapsing past ~20 steps.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Plan template caps phases (3-7) and states the boundary test verbatim. Planner agent.md: 'A phase boundary is valid only if the tree compiles and existing tests pass at that boundary. If a change would break consumers, the consumers go in the same phase. Prefer shadowing (introduce a parallel symbol, cut over in a final phase) to editing a live path across phases.'
- **If a reviewer is used, it must be in a fresh context that never saw the coder's reasoning, and its findings must be bounded.**
  - *Applies to:* both
  - *Why:* Cognition reports production numbers (2 bugs per PR, ~58% severe) and specifies the load-bearing detail: coder and reviewer share no context beforehand. Anthropic supplies the bounding requirement from the other side: 'A reviewer prompted to find gaps will usually report some, even when the work is sound', producing extra abstractions and tests for impossible cases; one practitioner watched a single CREATE TABLE balloon into a 200-line script across review rounds.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Any review dispatch line must be: 'Review the diff against <plan file>. Check every requirement is implemented, listed edge cases have tests, and nothing outside scope changed. Report only gaps affecting correctness or the stated requirements. Style preferences and speculative hardening are out of scope.' The reviewer gets read-only tools and is never given the implementer's transcript.
- **Model and tool selection live in frontmatter, never in prose, and the implementer cannot spawn subagents.**
  - *Applies to:* both
  - *Why:* Measured: parent on Opus with inherited-Opus subagents 762,226 metered input tokens / 8m00s vs Haiku-pinned 481,387 / 3m45s. Prose model directives get forgotten as context fills (one practitioner burned $120 in 75 minutes for exactly this). Depth is unbounded by default: one probe recursed ~30 levels before cancelling; Anthropic warns cost can multiply 10x when a subagent spawns subagents; Agent Teams simply forbids nested teams.
  - *Confidence:* reasonable-consensus
  - *Concrete implication:* Both agent files declare model: and tools: in frontmatter and never say 'use a cheaper model where appropriate' in the body. Implementer frontmatter excludes the delegation tool entirely; the body says 'You do not spawn subagents. If the work needs decomposition, stop and report that to the planner.' Note the caveat: frontmatter pins have been reported silently ignored, so verify usage rather than assuming.

## Antipatterns

- **Role/persona agent rosters (backend-engineer, ui-planner, security-auditor) working the same unit of work.**
  - *Failure mode:* Anthropic measured subagents spending more tokens on coordination than on work. Google/MIT measured 39-70% degradation on sequential tasks for every multi-agent variant. Seven role-shaped planners produced internally consistent but mutually contradictory specs neither could see. The role sentence changes register, not capability.
  - *Guard:* Planner agent.md states: 'Planning, implementation, testing and review are phases of one unit of work, not separate agents. Never create a subagent whose only differentiator is a job title.'
- **'Use a subagent to verify' / 'include a final verification step for any non-trivial task' as a standing instruction.**
  - *Failure mode:* Anthropic's Opus 5 guidance says to delete exactly these strings: they cause over-verification and removing them 'reduces wasted tokens with no loss in quality'. Anthropic's delegation-restraint prompt adds 'Do not spawn a subagent to review, re-verify, or double-check work you can verify inline.' Observed in the wild as a single CREATE TABLE ballooning into a 200-line script.
  - *Guard:* Neither agent file contains the string 'subagent to verify'. Replace with a command-level gate: the automated-verification commands in the plan must pass, exit codes checked, output pasted.
- **Plan steps written as intentions ('improve error handling in the auth module', 'make the API cleaner').**
  - *Failure mode:* The implementer self-certifies. 'Claude stops when the work looks done. Without a check it can run, looks done is the only signal available, and you become the verification loop.' MAST: no/incomplete verification 8.2%, incorrect verification 9.1%.
  - *Guard:* Planner agent.md: 'Every step names a file path and ends in a command. If you cannot write the command, the step is not ready to hand off.' Add the falsification test: 'If your verification section could be filled in without knowing this project's build tooling, it is decoration.'
- **Plan steps naming no file, or an area of concern instead of a location.**
  - *Failure mode:* The implementer starts cold, cannot resolve 'the model', and either re-explores the whole codebase (destroying the context saving that justified the split) or guesses. Localization is the widest measured accuracy gap in the corpus: 81.67% vs 47.00% ground-truth hit rate.
  - *Guard:* Plan template uses file paths as section headings tagged [MODIFY]/[NEW]/[DELETE]. Planner agent.md ships negative examples: 'Create User model' is wrong; 'Create User model in src/models/user.py' is right.
- **Padding the plan with extra phases or writing a long thorough context file because more must be better.**
  - *Failure mode:* Measured harm. Adding an obviously sensible early regression-test phase degraded a model; 'the negative impact of a bad, incomplete plan is greater on trajectories than the impact of no plan at all'. ETH Zurich: LLM-generated repo context files cut success ~3% while raising cost 20-23%. Anthropic: bloated CLAUDE.md causes Claude to ignore actual instructions.
  - *Guard:* Planner agent.md carries the pruning test verbatim ('For each line ask: would removing this cause a mistake? If not, cut it') plus 'Do not add a phase because it looks thorough. If you are unsure whether a phase belongs, omitting the plan entirely is safer than shipping one with a phase you cannot justify.'
- **Relying on CLAUDE.md, agent-definition bodies, rules files or hooks to carry conventions to the implementer.**
  - *Failure mode:* Systematic silent non-compliance across the majority of execution, with no user-visible signal. Four propagation mechanisms tried across 11 production agents, all failed. Forensics over 296 subagent sessions: zero memories persisted, commits with wrong git identity, retry loops against a service a memory forbade, an Explore subagent recommending exactly the path format CLAUDE.md documented as broken.
  - *Guard:* Plan template has a mandatory 'Conventions in force' block. Planner agent.md: 'Copy the rules the implementer needs into the plan verbatim. Never write see CLAUDE.md or follow project conventions.'
- **Giving the planner write tools, or an allowlist without closing the shell write path.**
  - *Failure mode:* It starts implementing mid-plan and the human approval gate silently disappears. A tool allowlist alone leaves bash -c 'cat > file', heredocs and > redirects open. Anthropic shipped delegate mode as a product feature because the prompt-level version failed.
  - *Guard:* Planner frontmatter excludes Edit/Write/NotebookEdit/delegation. Body enumerates forbidden shell verbs and redirect forms explicitly, and names the plan file as the only writable path.
- **'Based on your findings, implement it' / 'based on the research, fix the bug'.**
  - *Failure mode:* Named and banned in Claude Code's own subagent-prompt guidance: those phrases 'push synthesis onto the agent instead of doing it yourself'. You pay the full delegation cost (fresh context, re-exploration, report round-trip) and the hard reasoning still happens, in the agent with the least context.
  - *Guard:* Planner agent.md: 'Never delegate understanding. Write prompts that prove you understood: file paths, line numbers, what specifically to change. If you find yourself writing based on your findings, you have not finished planning.'
- **Fanning out over work that shares context, or two agents writing the same file.**
  - *Failure mode:* Measured 2.6x-5.9x metered input tokens versus sequential for the same small task, and slower wall-clock. Shared-file writes are silent data loss, not a reviewable correctness bug. The canonical anecdote is 40+ subagents each re-reading the same 1000-line file where one instance was far faster and cheaper.
  - *Guard:* Plan template requires per-unit 'Owned Files'. Planner agent.md: 'Two units may never name the same file. If a file must be touched by two units, sequence them or make that edit yourself. Parallelize only when file sets are disjoint and neither unit needs the other's output.'
- **Trusting a subagent's 'completed' status without checking the artifact.**
  - *Failure mode:* A harness can terminate a subagent mid-task on budget or context and report 'completed' to the parent with no truncation marker; the deliverable file was never written. Reproducible around ~18-20 tool uses. Compounded by quota retries that restart from blank context and redo finished work.
  - *Guard:* Implementer report contract ends with a fixed sentinel footer line; its absence means truncation. Planner agent.md: 'After every dispatch, verify the artifact exists (git diff --stat, test -f on the named paths, the plan file's checkboxes) before accepting a completion. Never treat a completion status as evidence.'
- **Long-running orchestrator sessions that rely on the conversation to hold the plan, the team and the orchestrator's own role.**
  - *Failure mode:* Compaction amnesia. One report: after four compactions in a single phase the lead lost its 'project manager only' role constraint and silently started implementing. Another: post-compaction the lead re-spawns teammates it thinks are missing, contributing to 30 Agent calls producing 107 subagent transcripts. Compaction preserves rules textually but demotes them from active constraints to historical context.
  - *Guard:* Both agent files state that all durable state lives in the plan file, and the planner re-reads it before each dispatch. Hard constraints go in a short append-only decisions ledger the planner re-reads at each major step, not in the conversation.
- **A persistent plan file that is never retired.**
  - *Failure mode:* Stale plans on disk get re-presented for the next, unrelated task and the loop only breaks when the file is deleted. Seven-plus independent confirmations.
  - *Guard:* One plan file per task, named for the task, in a dedicated directory. Both agent files carry: 'On completion, delete or archive the plan file. Never resume or extend a plan file for a different task.'
- **Effort or time estimates in the plan.**
  - *Failure mode:* Fabricated, non-actionable, and they anchor humans wrongly. Roo Code bans it in shipping production source in caps. No source in the corpus offers evidence in favour.
  - *Guard:* Plan template has no effort field. Planner agent.md: 'Never provide level-of-effort or time estimates. Break the work into clear, actionable steps instead.'
- **Unbounded reviewer ('find everything wrong with this') or adversarial review of the plan by opinion.**
  - *Failure mode:* Over-engineering: extra abstraction layers, defensive code, tests for cases that cannot happen. Reviewing a plan against a model's opinion is exactly the self-verification shown not to work; MAST's ChatDev intervention caps prompt-level gains at about +9pts against +15.6pts for structural change.
  - *Guard:* Review dispatches must name the artifact, name the checks, and bound the finding class ('report gaps, not style preferences'). Plan self-review is allowed only where it terminates in an external check: path existence, symbol existence, requirement-to-task coverage, or a trace against a concrete case with a known expected output.
- **The orchestrator carrying raw tool output or full subagent transcripts in its own context.**
  - *Failure mode:* Context is the orchestrator's scarce resource and degradation is non-uniform well before the documented limit, with topically-related-but-wrong content (failed approaches) hurting more than unrelated content. Mechanically, some harnesses leak raw subagent JSONL transcripts into the caller. Honest caveat: the claim that summarization improves quality is not supported; keep it for the budget reason, not the quality reason.
  - *Guard:* Planner agent.md: 'Ask for a bounded report (state a word or token cap). For large outputs, have the implementer write a file and return the path.' Implementer agent.md: 'Your report goes to the coordinator, not the user. Report outcomes with paths, line numbers and verbatim error text; do not paste full command transcripts.'
- **Citing Anthropic's 90.2%-over-single-agent number to justify a multi-agent coding setup.**
  - *Failure mode:* That result is a June 2025 breadth-first research eval at ~15x chat token cost, and the same post says 'most coding tasks involve fewer truly parallelizable tasks than research, and LLM agents are not yet great at coordinating and delegating to other agents in real time'. Coding shares mutable state and has dense dependencies, the exact PlanCraft profile where multi-agent lost 39-70%.
  - *Guard:* The planner's own decision rule must be about context economics and file disjointness, never about a research benchmark. Do not encode multi-agent-by-default anywhere in either file.

## Handoff contract

### Plan sections

- Header: task slug, plan file path, and the one-line statement of what will be true when this is done
- Context: why this change is being made, the problem it addresses, the intended outcome (recommended approach only; alternatives are pruned from the final artifact)
- Conventions in force: build / test / lint / typecheck commands, file and naming conventions, forbidden patterns, commit and identity rules, copied verbatim rather than referenced
- Evidence: what the planner actually ran or read, the verbatim output or error, what was ruled out, and what remains uncertain
- Existing code to reuse: file path plus symbol name for each function, utility or pattern the implementer should not reinvent
- Proposed Changes, grouped by phase; within a phase, one heading per file tagged with the operation ('### [MODIFY] src/auth/session.ts', [NEW], [DELETE]) and a short statement of what changes there. For a pattern repeated across many files: describe the pattern once and list 3-5 representative paths
- Interface contract (only when more than one unit): Exports this unit provides, Imports it consumes, and a note that agreed interfaces are immutable without planner approval
- Owned Files (only when parallelizing): the exact file list each unit may modify; no file appears under two units
- Per-phase Success Criteria, split into '#### Automated Verification' with the literal command inside each checkbox, and '#### Manual Verification' for what a human must judge
- Out of Scope: concrete named items that are explicitly not part of this change
- Definition of Done: stated purely as command outcomes plus the state of the plan file's checkboxes
- Halt surfaces: named conditions that stop work and escalate rather than proceed (auth/tokens/PII/CORS/sessions, destructive schema change, external API contract change, insufficient information)
- Open Questions: must be empty in the final artifact

### Report sections

- Plan file path and which phase(s) this report covers
- What changed: file path plus one line each; commit hash if committed (staging only the files actually changed, never git add -A)
- Verification run: each automated-verification command from the plan, its exit status, and its verbatim output for anything that failed
- Evidence for anything not decidable by command, with the observation quoted rather than characterized
- Deviations: for each, the block Step N / Expected / Found / Why it matters / Adjustment taken
- Assumptions: any ambiguity resolved by picking the most likely interpretation, stated explicitly
- Not done: unchecked plan items, blocked items and why, plus improvements noticed and deliberately not implemented as follow-ups
- One-sentence summary the coordinator can relay ('Added Redis cache implementation. Tests pass, typecheck clean. Committed abc123.' not 'I looked at files X, Y and Z.')
- A fixed terminal sentinel line, always last, so a truncated run is detectable by its absence

### Failure signaling

Four mechanisms, all explicit in both files. (1) Truncation: the implementer's report must end with a fixed sentinel line and the planner must verify the artifact independently (git diff --stat, existence of the named paths, checkbox state in the plan file) before accepting any completion; a 'completed' status is never evidence, because harnesses terminate subagents mid-task and report success with no marker. (2) Deviation: when the plan cannot be followed, the implementer emits Step N / Expected / Found / Why it matters / Proposed adjustment and proceeds with the adjustment unless the step touches a named halt surface, in which case it stops. It never silently skips and never silently improvises. (3) Stuck: the same failed approach is never retried more than once; after two failed attempts on one step the implementer stops and emits a blocked report rather than trying a third variation. Ambiguity is handled differently from impossibility: pick the most likely interpretation, state the assumption, continue. (4) Planner-side escalation: if the plan cannot be written without guessing, the planner writes one clear question and halts without producing a plan, rather than shipping a plan containing an open question.

## Structural conventions

- Frontmatter on both files: name (globally unique, plugin-scoped, avoiding default/worker/explorer), description containing a literal trigger phrase ('Use when ...') because that phrase is the routing signal, model, and an explicit tools allowlist.
- Planner tools: read-only set (file read, glob, grep, read-only bash) with Edit/Write/NotebookEdit and the delegation tool excluded. The measured spawn tax is ~27,400 tokens by default and ~22k of it is tool schemas, so a tight allowlist is a real saving, not hygiene.
- Implementer tools: no delegation tool at all. Depth cap is a capability, not an instruction.
- Read-only is stated twice for the planner: once in the allowlist, once in prose that names the shell escape hatches by name (>, >>, |, heredocs, /tmp, mkdir/touch/rm/cp/mv/git add/git commit/npm install) with the permitted read verbs enumerated.
- Plan file path is deterministic and inside the repo, derived from the task (e.g. .plans/<task-slug>.md), never a random name outside the project.
- Verification commands prefer a project-level entry point (make, package script) over raw tool invocations so they stay valid regardless of working directory.
- Write agent bodies in terms of actions rather than harness tool names ('Open the file', not 'Use the Read tool'), so the definitions degrade gracefully on other harnesses.
- Prefer stating goals over step-by-step scaffolding in the body; higher-capability models want altitude, and long scaffolded prompts spend attention on protocol compliance instead of the codebase.
- Keep both bodies short and default to the lean shape. Add structure only where you can name the failure it prevents; ceremony proportional to nothing is the most common defect in published agent files.
- Plan formatting: file paths as section headings tagged with the operation; checkboxes contain the literal command; no effort or time estimates anywhere; omit any section that would be empty rather than emitting a placeholder.
- Optional but cheap: stable requirement IDs with a trailing back-reference on each task (_Requirements: 2.1, 3.3_), which makes 'requirement with no task' and 'task with no requirement' a greppable set operation rather than an opinion.
- Both files carry an explicit statement that instructions in the dispatch/plan supersede any conflicting general instruction the implementer's own definition might contain, because the child carries its own role prompt that can conflict with the task.

## Evidence notes

### Battle tested

- Verification as the highest-leverage component: Agentless per-stage ablation (majority voting 25.67% -> +regression tests 27.00% -> +reproduction tests 32.00% on SWE-bench Lite) plus MAST's 23.5% of 1600+ annotated failures in verification/termination, plus Huang et al. ICLR 2024's negative result on intrinsic self-correction.
- Localization as the plan's core content: Agentless hierarchical localization 81.67% ground-truth hit rate vs 47.00% for direct localization; CodeR loses 8pts with fault localization removed.
- Authored control flow beats model-invented control flow at a given capability: Kimi-Dev holds the model constant, 60.4% SWE-bench Verified on the fixed Agentless workflow vs 48.6% pass@1 driving a free-form agent. Read as ordinal, not cardinal.
- Plans are advisory and reminders help: the 16,991-trajectory plan-compliance study states the scaffold provides no enforcement mechanism, and measures that reinjecting the plan every five steps improved success across all four models tested.
- A subpar or padded plan is worse than no plan: same study, plus ETH Zurich's AGENTbench (138 tasks, 12 repos) where LLM-generated context files cut success ~3% at +20-23% cost and human-written ones bought only ~4%.
- Adaptive, code-derived planning with a context-matched baseline: CodePlan gets 5/7 repos to pass build and correctness checks vs 0/7 for baselines given the same context but no plan, across 2-97 interdependent files. The strongest 'planning helps' result in the corpus, and its planner is symbolic rather than an LLM.
- Parallelism economics: Google Research + MIT, 180 configurations, +80.9% on the parallelizable benchmark but 39-70% degradation on the sequential one for every multi-agent variant, and 17.2x vs 4.4x error amplification for independent vs centralized.
- Capability restriction over prose: Roo ships Orchestrator with groups: [], Anthropic shipped delegate mode as a product feature because the prompt version failed, and four prompt-based propagation mechanisms across 11 production agents were documented as ignored.
- Spawn cost is measurable and large: 27,403 tokens default headless subagent (~22k of it tool schemas) vs 1,965 with tools: []; fan-outs measured at 2.6x-5.9x metered input tokens and slower wall-clock on small tasks.
- Handoff content matters most right after a failure: +12-19pts resolve rate at post-failed-test handoff points, and 20-59% fewer successor events for any context-bearing format.

### Cargo cult

- 'Use a subagent to verify' / 'include a final verification step for any non-trivial task'. Anthropic's Opus 5 guidance says to delete these strings outright. Replace with a command-level gate inside the implementer's own loop.
- Persona/role agent rosters. No source shows a role sentence changes capability rather than register; the strongest 'evidence' (MetaGPT's role-addition ablation) is a subjective 1-4 human score over 11 tasks on saturated benchmarks.
- Citing Anthropic's 90.2% multi-agent result for coding. It is a breadth-first research eval and the same post disclaims transfer to coding.
- 'Write a thorough spec / AGENTS.md / CLAUDE.md, more context is better.' Benchmarked as harmful twice (ETH AGENTbench; plan-compliance study), and Anthropic's own docs say bloated context files cause the model to ignore actual instructions.
- Multi-document spec-driven ceremony (constitution -> spec.md -> plan.md -> tasks.md -> code) with approval gates at each. 124k stars, zero published evaluation, and the maintainers ship a 15-line lean preset alongside 250-line templates in the same repo.
- Star-count-validated agent collections. VoltAgent's 23.8k-star multi-agent-coordinator is granted no delegation tool while promising 'Scalability to 100+ agents verified'; contains-studio has been dead for a year and ships 38 personas with no orchestration layer.
- Deep decomposition and wide fan-out as thoroughness. Returns saturate almost immediately (MapCoder: 9.1pts from k=1->5, 0.3pts from k=5->7) while cost and error compounding do not.
- Effort/time estimates in plans. Banned in Roo's shipping source; no supporting evidence anywhere.
- Relay-degradation numbers (90.7% -> 41.2% -> 22.5%; prose 8.5pts/stage vs structured 2.8pts/stage). No traceable primary source; likely a garbled derivative of the Google/MIT error-amplification figures. Do not build the structured-handoff argument on them.
- 'Give the agent a plan and it will follow it.' Compliance is model-dependent, drops ~13% on harder benchmarks, and the compliance-success correlation can invert.
- Adversarial review of the plan by three subagents ('super plan'). Traces to a single comment with no numbers, collides with over-verification guidance, and is plan-review-by-opinion, which is the self-verification shown not to work.
- SWE-bench Verified/Lite percentages as a reliable ranking of designs. SWE-ABS shows test-based benchmarks overstate success because patches pass weak suites while being semantically wrong; HumanEval/MBPP multi-agent claims are worse still (AgentCoder's 96.3% could not be reproduced, an independent attempt got 56.7% and 17.7%).

### Contested

- Structured fixed-field handoff notes vs raw traces. Everyone asserts structure wins; the one controlled test found raw traces improved successor resolve rate 6-15pts while curated structured notes managed 1-10pts, often not significant, at comparable token savings. Resolution for the brief: keep named fields for auditability and machine-checkability, but quote raw evidence inside them rather than compressing it away. Do not claim the structure is what makes it work.
- Whether the orchestrator holding only summaries improves quality. Universally asserted, never measured for coding orchestrators. Adopt it for the real reason (the orchestrator's context is a hard budget and degradation is non-uniform well before the limit) and drop the quality claim.
- Whether a planner/implementer split beats a single well-prompted agent at all. A compute-matched study found single-agent matched or beat every MAS topology including planner-workers at every thinking-token budget from 100 to 10k, with MAS only overtaking under heavy context corruption; mini-SWE-agent (~100 lines, bash only, no planner) reports >74% SWE-bench Verified; Cursor ships no planner. The split earns its place only when the single agent's context would genuinely degrade: large unfamiliar repo, multi-file change, or a genuinely disjoint parallel track. The planner should say so and decline when it does not apply.
- Model pinning for the implementer. The cost saving is measured (762,226 vs 481,387 input tokens, 8m00s vs 3m45s); the quality-neutrality claim is entirely unmeasured, and frontmatter pins have been reported silently ignored. Pin in frontmatter, verify usage, do not assume quality is unaffected.
- Cognition's 'Don't Build Multi-Agents' as settled anti-multi-agent doctrine. Zero numbers, and partially reversed by the same author ten months later into a narrower single-writer rule with production figures. Cite the reversal, not the original.
- Hook-based context injection (SubagentStart/PreCompact). Three practitioners independently converged on it; one reports building exactly that hook and having it ignored, and the injection is a spawn-time snapshot. Belt-and-braces only; never the sole channel, and it is harness config rather than agent-definition content.

## Best prompt excerpts

- **Claude Code, extracted system prompt for writing subagent prompts (v2.1.176)**
  - *Excerpt:* Any agent other than a fork starts with zero context. Brief the agent like a smart colleague who just walked into the room ... Lookups: hand over the exact command. Investigations: hand over the question, prescribed steps become dead weight when the premise is wrong. ... Never delegate understanding. Don't write 'based on your findings, fix the bug' or 'based on the research, implement it.' Those phrases push synthesis onto the agent instead of doing it yourself. Write prompts that prove you understood: include file paths, line numbers, what specifically to change.
  - *Why strong:* Four distinct rules in one block: cold-start framing, deliberate over-briefing so the child can make judgment calls, the lookup-vs-investigation split, and the sharpest available statement of what makes a planner/implementer split fail. Nearly every line converts directly into a planner system-prompt line.
- **Claude Code, extracted subagent-delegation-restraint prompt (v2.1.215)**
  - *Excerpt:* Subagents multiply cost and time: each one re-establishes context, re-explores, and reports back, and you then re-read its report. ... Do not fan out multiple subagents on a single small task. ... Do not spawn a subagent to review, re-verify, or double-check work you can verify inline. ... If you find yourself repeating what a subagent is doing, you should not have spawned it. ... brief it precisely the first time rather than launching, waiting, and re-briefing.
  - *Why strong:* Almost no community orchestrator prompt contains a restraint clause; this one is 100% restraint, and the spawn cost it names is independently measured at ~27,400 tokens per default subagent. The last clause is the practical counterweight to 'spawn agents in parallel' advice.
- **Claude Code best practices (official docs)**
  - *Excerpt:* Claude stops when the work looks done. Without a check it can run, 'looks done' is the only signal available, and you become the verification loop: every mistake waits for you to notice it.
  - *Why strong:* The cleanest one-sentence statement of why every plan step needs a command, and it pairs with the same doc's instruction to show evidence rather than assert success: the test output, the command run, and what it returned.
- **Anthropic, Building a multi-agent research system (engineering blog)**
  - *Excerpt:* [Subagents require] an objective, an output format, guidance on the tools and sources to use, and clear task boundaries.
  - *Why strong:* The most directly copyable line in the corpus, from the team that ran the eval, with the failure that motivated it stated: vague directives caused multiple subagents to run identical searches instead of dividing labor. It gives the planner a required schema for every unit it emits, including the two fields people most often drop.
- **HumanLayer, .claude/commands/create_plan.md (production, in-repo)**
  - *Excerpt:* #### Automated Verification:
- [ ] Migration applies cleanly: make migrate
- [ ] Type checking passes: npm run typecheck
#### Manual Verification:
- [ ] Feature works as expected when tested via UI
- [ ] Edge case handling verified manually
  - *Why strong:* The command is inside the checkbox. That is what makes a later validation pass possible at all: it can re-execute each automated command against the repo and report per-phase Fully/Partially implemented, catching false completions. Four independent teams converged on this two-bucket shape.
- **Roo Code, packages/types/src/mode.ts, Orchestrator mode customInstructions (shipping source)**
  - *Excerpt:* These instructions must include: All necessary context from the parent task ... A clearly defined scope ... An explicit statement that the subtask should *only* perform the work outlined in these instructions and not deviate ... a concise yet thorough summary of the outcome ... keeping in mind that this summary will be the source of truth used to keep track of what was completed on this project. ... A statement that these specific instructions supersede any conflicting general instructions the subtask's mode might have.
  - *Why strong:* A five-item required checklist for every dispatch, from production source. The fifth item is one nobody else thinks of and it addresses a real mechanism: the child carries its own role prompt that can conflict with the task. The fourth turns the return summary into a durable project record.
- **Claude Code, extracted Plan agent prompt (v2.1.118)**
  - *Excerpt:* You are STRICTLY PROHIBITED from: Creating new files ... Creating temporary files anywhere, including /tmp; Using redirect operators (>, >>, |) or heredocs to write to files ... Use Bash ONLY for read-only operations (ls, git status, git log, git diff, find, cat, head, tail); NEVER use Bash for: mkdir, touch, rm, cp, mv, git add, git commit, npm install, pip install
  - *Why strong:* Read-only enforced twice, allowlist plus prose, with the prose closing the shell holes the allowlist cannot. The permitted/forbidden verb lists are directly liftable, and the specificity is obvious scar tissue rather than theory.
- **Claude Code, extracted phase-four-of-plan-mode prompt (v2.1.219)**
  - *Excerpt:* Include only your recommended approach, not all alternatives ... Name the critical files to be modified. For changes that repeat a pattern across many files, describe the pattern once and list a few representative paths, do not enumerate every file or line number ... Reference existing functions and utilities you found that should be reused, with their file paths ... Include a verification section describing how to test the changes end-to-end.
  - *Why strong:* Fully specifies a plan file in six lines, including the two exceptions most templates miss: prune alternatives from the final artifact, and do not enumerate repeated changes. The reuse clause is the anti-reinvention rule that the researched-vs-unresearched plan comparison supports.
- **wshobson/agents, plugins/ship-mate/agents/implement.md**
  - *Excerpt:* Before implementing, check each step in the plan: Does each referenced file path exist? ... If a plan step is impossible or contradictory: do not silently skip it. Flag it: Plan deviation required: Step [N] / Issue / Proposed adjustment / Proceeding with adjustment unless instructed otherwise. ... If any code touches authentication, authorisation, tokens, PII, CORS, or session management, halt immediately and flag.
  - *Why strong:* A pre-flight pass that catches stale plans cheaply, plus a deviation block that is non-blocking by default (keeps autonomy, leaves an audit trail), plus a named list of surfaces that convert the default into a hard stop. This is the single best implementer-side excerpt in the corpus.
- **Claude Code, extracted coordinator-worker instructions (v2.1.217)**
  - *Excerpt:* Complete exactly what was asked. Don't fix unrelated issues you discover, suggest them as follow-ups instead. ... Only stage files you actually changed, never use `git add .` or `git add -A`. ... If the task is ambiguous, pick the most likely interpretation and note your assumption. Don't retry the same failed approach more than once. ... Good summary: 'Added Redis cache implementation. Tests pass, typecheck clean. Committed abc123.' Bad summary: 'I looked at files X, Y, and Z.'
  - *Why strong:* Every clause is concrete and each maps to a measured failure: scope creep, parallel-worker file sweeping, ambiguity-blocking, step repetition (15.7% of MAST failures), and activity-reporting instead of outcome-reporting. The good/bad summary pair teaches the report contract better than any description of it.
- **github/spec-kit, templates/commands/tasks.md**
  - *Excerpt:* CORRECT: - [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py
WRONG: - [ ] Create User model (missing ID and Story label)
WRONG: - [ ] T001 [US1] Create model (missing file path)
[P] marker: include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
  - *Why strong:* A formal grammar with negative examples, which constrains behavior far better than an adjective. The [P] definition reduces the parallelism decision to a mechanical, checkable test rather than a judgment call.
- **Evaluating Plan Compliance in Autonomous Programming Agents (16,991 trajectories)**
  - *Excerpt:* the plan is only advisory: it is included in the system prompt, but the scaffold's execution engine provides no mechanism to enforce it ... The negative impact of a bad, incomplete plan is greater on trajectories than the impact of no plan at all.
  - *Why strong:* Two sentences that should govern the whole design. The first kills the assumption behind most planner prompts and licenses periodic reinjection as the mitigation with measured support. The second is the argument for a minimal, high-confidence plan over an ambitious one, and for declining to plan at all when unsure.
