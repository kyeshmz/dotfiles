# Evidence Research — Sources, Approaches & Verbatim Prompt Excerpts (Sweep 2)

Raw material behind `02-planner-implementer-brief-evidence.md`. Four research agents: papers, forums, GitHub artifacts, production blogs.

## Contents

1. [High-signal practitioner writing and production engineering reports on planner/orchestrator agents for coding ](#sweep-1)
2. [GitHub-first](#sweep-2)
3. [Academic literature (arXiv / ACL / ICLR / NeurIPS / FSE / EMNLP) on planner-orchestrator design for multi-agen](#sweep-3)
4. [Practitioner forums (HN threads + comments, GitHub issues on anthropics/claude-code, measured third-party benc](#sweep-4)

---

## Sweep 1

**Angle.** High-signal practitioner writing and production engineering reports on planner/orchestrator agents for coding — with an explicit split between claims backed by benchmarks or production deployment and claims that are merely popular.

### Sources (21)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | Google Research + MIT Media Lab: 180 agent configurations across 5 architectures (single, independent, centralized, decentralized, hybrid) and 4 benchmarks (Finance-Agent, BrowseComp-Plus, PlanCraft, Workbench). The single best quantitative answer to 'when should I use subagents at all'. | https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/ |
| `peer-reviewed-or-benchmarked` | ETH Zurich SRI Lab, Feb 2026: 'Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?' Built AGENTBENCH (138 tasks / 12 repos from ~5,700 PRs), tested Claude Code, Codex, Qwen Code with no / LLM-generated / human-written context files. | https://www.sri.inf.ethz.ch/publications/gloaguen2026agentsmd |
| `peer-reviewed-or-benchmarked` | 'Evaluating Plan Compliance in Autonomous Programming Agents' (Liu, Dehghan, Ganhotra, Hirzel, Jabbarvand; Apr 2026). 16,991 SWE-agent trajectories, 4 LLMs, SWE-bench Verified + Pro, 8 plan variations. Directly measures whether agents follow the plan they were given. | https://arxiv.org/abs/2604.12147 |
| `peer-reviewed-or-benchmarked` | Chroma Research 'Context Rot': 18 frontier models (GPT-4.1, Claude 4, Gemini 2.5, Qwen3) measured on how accuracy degrades with input length under controlled conditions — distractors, needle-question similarity, haystack structure, repeated-words. | https://www.trychroma.com/research/context-rot |
| `peer-reviewed-or-benchmarked` | Geng & Neubig, 'Effective Strategies for Asynchronous Software Engineering Agents' (Mar 2026). Tests task-specification detail, planning phases, scoping, and handoff protocols for async agents. | https://arxiv.org/pdf/2603.21489 |
| `primary-official` | Anthropic engineering: the orchestrator-worker Research system. Eight prompt-engineering principles including 'teach the orchestrator how to delegate' (the four required fields of a subagent brief) and explicit effort-scaling rules. Also states plainly why coding parallelizes worse than research. | https://www.anthropic.com/engineering/multi-agent-research-system |
| `primary-official` | Anthropic's decision guide for multi-agent. Three legitimate reasons (context pollution, parallelization, specialization), explicit warning against role-based decomposition, and the verification-subagent pattern. | https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them |
| `primary-official` | Anthropic engineering: compaction, structured note-taking, sub-agent architectures, just-in-time context, and the 'right altitude' framing for system prompts. Source of the concrete subagent return-value budget. | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents |
| `primary-official` | Claude Code official best practices (2026 revision). Explore→Plan→Implement→Commit, 'give Claude a way to verify its work', subagents-for-investigation, adversarial review subagent, writer/reviewer split, fan-out with claude -p, and a named failure-pattern list. | https://code.claude.com/docs/en/best-practices |
| `primary-official` | Claude Code Agent Teams docs (experimental, v2.1.178+). The most detailed public spec of a production orchestrator: team lead vs teammates, shared task list with file-locked claiming, mailbox messaging, plan-approval gate, delegate mode, and an explicit limitations list. | https://code.claude.com/docs/en/agent-teams |
| `primary-official` | Amp (Sourcegraph spinout) owner's manual: subagent semantics and the Oracle tool. States the subagent isolation contract explicitly — no inter-subagent communication, no mid-task steering, no inherited conversation context, main agent receives only the final summary. | https://ampcode.com/manual |
| `primary-official` | GitHub spec-kit: the Constitution → Specify → Plan → Tasks pipeline, and the convention that plan.md decomposes into atomic tasks each with objective, inputs, outputs, and an acceptance check. | https://github.com/github/spec-kit/blob/main/spec-driven.md |
| `practitioner-battle-tested` | Cognition (Devin) June 2025: the canonical anti-multi-agent argument. Two principles (share full agent traces, not messages; conflicting implicit decisions produce bad results), the Flappy Bird subagent failure example, and the recommendation of a single-threaded linear agent plus a dedicated context-compression model. | https://cognition.com/blog/dont-build-multi-agents |
| `practitioner-battle-tested` | Cognition, April 2026 — the reversal/refinement of the above by the same author (Walden Yan). Introduces the 'single writer' principle and three patterns that survived production: Code-Review-Loop, Smart Friend, map-reduce-and-manage. | https://cognition.com/blog/multi-agents-working |
| `practitioner-battle-tested` | Simon Willison, Agentic Engineering Patterns, Subagents chapter (2026). Argues the primary value of subagents is preserving root context, shows a real Explore-subagent prompt and the shape of a good return payload. | https://simonwillison.net/guides/agentic-engineering-patterns/subagents/ |
| `practitioner-battle-tested` | Armin Ronacher, 'Agent Design Is Still Hard' (Nov 2025). Failure containment via subagents, shared virtual filesystem as the handoff medium, avoiding tool 'dead ends', reinforcement messages after tool calls, explicit cache management, and the output-tool argument that agents are not chat apps. | https://lucumr.pocoo.org/2025/11/21/agents-are-hard/ |
| `practitioner-battle-tested` | Latent Space, May 2026: Cognition's Walden Yan + OpenInspect's Cole Murray on async/cloud agents. Devin production numbers, spec-to-PR workflow, brain/machine separation, manager-Devin multi-agent status, and codebase decay without review. | https://www.latent.space/p/cognition |
| `practitioner-battle-tested` | Third-party distillation of Sourcegraph/Amp engineers (Thorsten Ball, Quinn Slack) on what they learned building Amp: context as a sterile operating room, Oracle multi-model pattern, deliberately NOT optimizing token usage, CI as the async feedback loop. | https://www.nibzard.com/ampcode/ |
| `popular-but-unvalidated` | Addy Osmani on writing specs for coding agents: six required sections, the three-tier boundary system (always / ask first / never), acceptance-criteria structure. Cites a GitHub analysis of 2,500+ agent config files. | https://addyosmani.com/blog/good-spec/ |
| `popular-but-unvalidated` | Addy Osmani on multi-agent coding: subagents vs Agent Teams vs Ralph Loop, file-ownership briefs, per-agent token budgets, named failure modes. Honest enough to cite the ETH AGENTS.md result against itself. | https://addyosmani.com/blog/code-agent-orchestra/ |
| `unverified` | 'Architectural Design Decisions in AI Agent Harnesses' (Apr 2026): census of 70 public agent-system codebases across subagent architecture, context management, tool systems, safety, orchestration. Useful as a map of what people actually build. | https://arxiv.org/abs/2604.18071 |

### Verbatim prompt excerpts (16)

**Anthropic, Building a multi-agent research system (engineering blog)**

```
Teach the orchestrator how to delegate. [Subagents require] an objective, an output format, guidance on the tools and sources to use, and clear task boundaries.
```

> The most directly copyable line in the corpus. It gives a planner's system prompt a required schema for every task it emits, and it names the two fields people most often omit — output format and boundaries.

**Anthropic, Building a multi-agent research system**

```
Simple fact-finding [uses] 1 agent with 3-10 tool calls; direct comparisons [use] 2-4 subagents with 10-15 calls each; complex research [uses] more than 10 subagents.
```

> Effort-scaling as literal numbers embedded in the orchestrator prompt rather than as judgment. Trivially adaptable to coding: 'single-file fix = no delegation; 2-4 independent modules = one subagent each; anything else, replan.'

**Anthropic, When to use multi-agent systems (claude.com blog)**

```
You MUST run the complete test suite before marking as passed.
```

> Anthropic reports that without this explicit comprehensive-validation requirement, 'verification agents take shortcuts.' It is a caps-locked instruction in a vendor blog because the softer phrasing measurably failed.

**Claude Code best practices (official docs)**

```
Use a subagent to review the rate limiter diff against PLAN.md. Check that every requirement is implemented, the listed edge cases have tests, and nothing outside the task's scope changed. Report gaps, not style preferences.
```

> A complete plan-conformance review prompt in four clauses: name the artifact, name the plan file, name the three checks, bound the finding class. Note the third check — scope creep detection — which most review prompts omit.

**Claude Code best practices (official docs)**

```
The most useful specs are self-contained: they name the files and interfaces involved, state what is out of scope, and end with an end-to-end verification step that proves the feature works. Time spent making the spec precise pays off more than time spent watching the implementation.
```

> This is the plan-artifact contract in one sentence, and it justifies the whole planner/implementer split economically: precision at handoff beats supervision during execution.

**Claude Code best practices (official docs)**

```
I want to build [brief description]. Interview me in detail using the AskUserQuestion tool. Ask about technical implementation, UI/UX, edge cases, concerns, and tradeoffs. Don't ask obvious questions, dig into the hard parts I might not have considered. Keep interviewing until we've covered everything, then write a complete spec to SPEC.md.
```

> Anthropic's own prescribed planner behavior is interrogate-then-write-a-file, followed by 'start a fresh session to execute it.' The fresh session is the point: the implementer's context contains the spec and nothing else.

**Claude Code best practices (official docs)**

```
Claude stops when the work looks done. Without a check it can run, "looks done" is the only signal available, and you become the verification loop: every mistake waits for you to notice it.
```

> The cleanest statement of why every plan step needs a command. Pairs with their instruction to 'have Claude show evidence rather than asserting success: the test output, the command it ran and what it returned.'

**Claude Code agent teams (official docs)**

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module at src/auth/ for security vulnerabilities. Focus on token handling, session management, and input validation. The app uses JWT tokens stored in httpOnly cookies. Report any issues with severity ratings."
```

> A model of a cold-start brief: exact path, three named focus areas, a fact the child cannot discover cheaply (JWT in httpOnly cookies), and the required output shape (severity ratings). Every clause exists because the child inherits no conversation history.

**Claude Code agent teams (official docs)**

```
To influence the lead's judgment, give it criteria in your prompt, such as "only approve plans that include test coverage" or "reject plans that modify the database schema."
```

> If your orchestrator gates on child plans, the approval criteria must be explicit and preferably enumerable as reject-conditions. An orchestrator without stated criteria approves almost everything.

**Claude Code best practices (official docs)**

```
For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
```

> A falsifiable pruning test for the plan/context artifact, and the only defense against the ETH-benchmarked harm of bloated context files. Applies equally to plan.md.

**Simon Willison, Agentic Engineering Patterns — Subagents**

```
Find the code that implements the diff view for 'chapters' in this Django blog. I need to find: 1. Templates that render diffs 2. Python code that generates diffs 3. Any JavaScript related to diff rendering 4. CSS styles for the diff view
```

> An exploration-subagent brief structured as an enumerated retrieval contract rather than an open question. The return payload it produced — file locations, line numbers, grouped by category — is the shape a planner actually needs to write file-path-specific steps.

**Cognition, Don't Build Multi-Agents**

```
Share context, and share full agent traces, not just individual messages. / Actions carry implicit decisions, and conflicting decisions carry bad results.
```

> The second principle is the real constraint on parallel implementers: it is not that they duplicate work, it is that each action encodes an unstated design decision. A planner prompt can neutralize much of this by pre-deciding the interfaces and naming them in the plan.

**Cognition, Multi-Agents: What's Actually Working (Apr 2026)**

```
Multi-agent systems work best today when writes stay single-threaded and the additional agents contribute intelligence rather than actions.
```

> The one-line architecture rule from the team that argued hardest against multi-agent and then partially reversed. It is a sharper and more defensible constraint than 'use subagents for parallelizable work'.

**Claude Code best practices (official docs)**

```
A reviewer prompted to find gaps will usually report some, even when the work is sound, because that is what it was asked to do. Chasing every finding leads to over-engineering: extra abstraction layers, defensive code, and tests for cases that can't happen.
```

> Rare vendor honesty about a second-order failure of the verification pattern. Any orchestrator prompt that spawns reviewers needs a corresponding triage instruction, not just a review instruction.

**Amp owner's manual**

```
Subagents work in isolation — they can't communicate with each other, you can't guide them mid-task, they start fresh without your conversation's accumulated context, and the main agent only receives their final summary.
```

> The subagent contract stated as four hard constraints. Every one of them is a requirement on the planner: the brief must be complete, self-contained, non-interactive, and specify what the summary must contain.

**Claude Code best practices (official docs)**

```
If you could describe the diff in one sentence, skip the plan.
```

> A concrete escape hatch that belongs in any planner's system prompt. Planning has real cost, and the benchmarked evidence says an unnecessary or padded plan can reduce success.

### Approaches (12)

- **Orchestrator-worker with a four-field delegation brief (Anthropic Research)** — A lead agent analyzes the query, writes its plan to memory (critical because context approaches 200k tokens and can be lost), then spawns subagents. Each subagent brief must contain exactly four things: an objective, an output format, guidance on which tools and sources to use, and clear task boundaries. Effort is scaled by explicit numeric rules baked into the orchestrator prompt (simple fact-find = 1 agent / 3-10 tool calls; comparison = 2-4 subagents / 10-15 calls each; complex = 10+ subagents). Subagents return condensed summaries; for structured outputs, subagents instead write to an external artifact store and return a lightweight reference so large payloads never transit the orchestrator's context. A separate CitationAgent does a final pass.
  - *Reported results:* Multi-agent Opus-4-lead + Sonnet-4-subagents beat single-agent Opus 4 by 90.2% on Anthropic's internal research eval. Costs ~15x the tokens of chat (single agents ~4x). Token usage alone explains 80% of variance on BrowseComp. Parallel tool calling cut research time up to 90%. A self-improving tool-description agent cut task completion time 40%. Anthropic explicitly says this does NOT transfer to coding: 'most coding tasks involve fewer truly parallelizable tasks than research, and LLM agents are not yet great at coordinating and delegating to other agents in real time.'
  - *Source:* https://www.anthropic.com/engineering/multi-agent-research-system
- **Single-threaded linear agent + context-compressing model (Cognition 2025)** — Reject subagent decomposition entirely. One agent, one continuous thread, every action sees every prior action. When the thread outgrows the window, insert a dedicated LLM whose only job is to compress the action history into key details, events, and decisions — potentially a fine-tuned smaller model. The stated principles: (1) share context, and share full agent traces, not just individual messages; (2) actions carry implicit decisions, and conflicting decisions carry bad results.
  - *Reported results:* No benchmark numbers. Argued from a concrete production failure class (the Flappy Bird example: one subagent builds a Super Mario background, another builds an inconsistent bird, the orchestrator cannot reconcile them). Author concedes the compression approach is 'hard to get right'. This is the highest-quality reasoning-from-experience source in the space, and it is explicitly superseded by the same author 10 months later.
  - *Source:* https://cognition.com/blog/dont-build-multi-agents
- **Single-writer multi-agent: map-reduce-and-manage, Code-Review-Loop, Smart Friend (Cognition 2026)** — The reversal. Multi-agent works only in the narrow class where writes stay single-threaded and the extra agents contribute intelligence rather than actions. Three shapes: (a) Code-Review-Loop — a reviewer agent that deliberately shares NO context with the coder before reviewing, so it is not anchored by the coder's reasoning; (b) Smart Friend — the primary model calls out to a stronger model as a tool, framed as a capability router not a difficulty escalator, and it only works when both models are strong; (c) map-reduce-and-manage — a manager splits work, children execute in isolated boxes, the manager synthesizes and reports. Unstructured swarms of negotiating agents are called 'mostly a distraction'.
  - *Reported results:* Devin Review catches an average of 2 bugs per PR, ~58% of them severe — in production. Enterprise Devin usage ~8x in 6 months. Cross-frontier pairing (Claude + GPT) 'produced real gains in the trickiest scenarios'. Manager Devin is live. Honest failure note: 'Managers trained on small-scoped delegation default to being overly prescriptive, which backfires when the manager lacks deep codebase context,' and map-reduce 'took more context engineering than we expected.' On the podcast, Walden still says 'most practical use on a day-to-day basis has been one single Devin.'
  - *Source:* https://cognition.com/blog/multi-agents-working
- **Centralized coordination as an architecture choice (Google Research + MIT)** — Treat the coordination topology itself as the design variable. Five architectures compared head to head: single-agent, independent (fan-out with no coordinator), centralized (orchestrator mediates), decentralized (peer-to-peer), hybrid. Route by task property — decomposability and tool count — rather than by intuition.
  - *Reported results:* The only large controlled comparison I found: 180 configurations, 4 benchmarks. Centralized coordination gained +80.9% over single agent on the parallelizable Finance-Agent. On the sequential PlanCraft benchmark, EVERY multi-agent variant degraded performance by 39-70%. Independent multi-agent amplified errors 17.2x; centralized contained amplification to 4.4x. Their predictive model (R²=0.513) picks the right coordination strategy for 87% of unseen configurations.
  - *Source:* https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/
- **Report-back-only subagents (Claude Code / Amp Task tool)** — The main agent spawns a subagent with its own fresh context window and tool allowlist; the subagent explores, and returns a single summary. There is no mid-task steering, no inter-subagent messaging, and no inherited conversation history. Amp states the contract explicitly: 'Subagents work in isolation — they can't communicate with each other, you can't guide them mid-task, they start fresh without your conversation's accumulated context, and the main agent only receives their final summary.' Subagent definitions live in .claude/agents/*.md with frontmatter for name, description, tools allowlist, and model.
  - *Reported results:* No published benchmarks. Anthropic's docs justify it purely on the context-window constraint ('performance degrades as it fills'), which Chroma's 18-model study does independently support. Simon Willison's position: 'the main value of subagents is in preserving that valuable root context and managing token-heavy operations' — and he cautions against reflexive use because a root agent with enough tokens can self-review.
  - *Source:* https://ampcode.com/manual
- **Agent Teams: shared task list + peer mailbox + delegate mode (Claude Code, 2026)** — A lead session spawns full peer Claude Code instances. Coordination is via a file-backed shared task list (~/.claude/tasks/{team}/) with pending/in-progress/completed states, declared dependencies that auto-unblock, and file locking on claim to prevent races. A mailbox (~/.claude/teams/{team}/inboxes/{agent}.json) carries direct peer messages. Delegate mode (Shift+Tab) restricts the lead to coordination-only tools so it stops implementing. An optional plan-approval gate keeps each teammate in read-only plan mode until the lead approves its plan; rejection returns feedback and the teammate resubmits. Teammates load CLAUDE.md/MCP/skills but explicitly do NOT inherit the lead's conversation history.
  - *Reported results:* No efficacy numbers published; the docs are candid that this is experimental and costs 'significantly more tokens'. Documented failure modes are the useful part: the lead starts implementing instead of waiting; the lead declares done before teammates finish; teammates fail to mark tasks complete and block dependents; teammates stop on errors instead of recovering; two teammates editing one file overwrite each other. Prescribed sizing: 3-5 teammates, 5-6 tasks per teammate, and 'three focused teammates often outperform five scattered ones.'
  - *Source:* https://code.claude.com/docs/en/agent-teams
- **Explore → Plan → Implement → Commit with a fresh-session boundary at the plan (Anthropic)** — Phase 1 in read-only plan mode: read named directories, answer questions, write nothing. Phase 2: produce a plan the human can open in an editor (Ctrl+G) and edit. Phase 3: exit plan mode and implement 'verifying against its plan', with tests run in the same turn. Phase 4: commit. The stronger variant: have the model interview the user with AskUserQuestion until everything is covered, write SPEC.md, then START A FRESH SESSION to execute it — the implementer's context contains the spec and nothing else. Explicit anti-overhead rule: 'If you could describe the diff in one sentence, skip the plan.'
  - *Reported results:* No numbers; presented as patterns 'proven effective across Anthropic's internal teams'. The spec-quality prescription is unusually concrete: 'The most useful specs are self-contained: they name the files and interfaces involved, state what is out of scope, and end with an end-to-end verification step that proves the feature works. Time spent making the spec precise pays off more than time spent watching the implementation.'
  - *Source:* https://code.claude.com/docs/en/best-practices
- **Adversarial review subagent scoped against the plan file** — After implementation, spawn a reviewer in a fresh context that sees only the diff and the criteria — not the reasoning that produced the change. Two variants: a generic correctness review (/code-review), or a plan-conformance review where you name the artifact: check every requirement in PLAN.md is implemented, every listed edge case has a test, and nothing outside scope changed. Findings return into the implementing session so it can fix and re-review without a human relaying. Cognition's version pushes further: coder and reviewer share no context at all beforehand.
  - *Reported results:* Cognition reports production numbers (2 bugs/PR, 58% severe). Anthropic reports no numbers but flags a real second-order failure: 'A reviewer prompted to find gaps will usually report some, even when the work is sound, because that is what it was asked to do. Chasing every finding leads to over-engineering.' Google/MIT's verification finding is consistent — centralized aggregation contains error amplification (4.4x vs 17.2x).
  - *Source:* https://code.claude.com/docs/en/best-practices
- **Ralph Loop: fixed prompt, fresh context each iteration, state entirely external** — There is no orchestrator agent at all. A fixed prompt is fed to an agent in an infinite loop; every iteration begins with a clean context window. All continuity lives outside the model: git commit history as the handoff boundary, a progress log, a task state file (tasks.json), and AGENTS.md as long-term semantic memory. Pick → implement → validate → commit → reset.
  - *Reported results:* No controlled evidence. Popular in practitioner circles and noted by Thoughtworks Radar as a named technique. The interesting property for prompt authors: it is the strongest possible expression of 'the implementer starts cold' — if the plan file is not sufficient, the loop cannot make progress, so plan quality is directly and continuously tested.
  - *Source:* https://addyosmani.com/blog/code-agent-orchestra/
- **Spec-driven development pipeline (spec-kit: Constitution → Specify → Plan → Tasks)** — Four artifacts, versioned in the repo. A constitution holds invariant project rules; a spec states what and why; plan.md states how; tasks decompose plan.md into atomic, independently-shippable units. Each task carries: a single objective, inputs (files to read, related specs), outputs (files to create/modify, tests to write), and an acceptance check. Verification is a step of the task, not a separate phase.
  - *Reported results:* No efficacy data published by the project. The known failure mode reported by early adopters is spec/code drift — specs and code fall out of sync unless updating the spec is part of the workflow. Note the tension with the ETH benchmark: more written repo context is not automatically better.
  - *Source:* https://github.com/github/spec-kit/blob/main/spec-driven.md
- **Oracle / Smart Friend: a stronger model exposed to the primary agent as a tool** — Rather than making the expensive model the orchestrator, the cheap fast model drives the loop and calls out to a high-reasoning model as a named tool for architecture decisions and stuck debugging. Amp: 'This model is available to Amp's main agent through a tool called oracle... We recommend explicitly asking Amp's main agent to use the oracle when you think it will be helpful.' Cognition frames the same shape as a capability router, not a difficulty escalator.
  - *Reported results:* No benchmarks. Cognition reports it failed when the primary was too weak (SWE 1.5 'was not good enough at being the primary model for this setup') and worked when both models were strong — a real negative result, which is rare and worth trusting.
  - *Source:* https://cognition.com/blog/multi-agents-working
- **Brain/machine separation with per-subagent isolated environments (Devin)** — The agent's reasoning process runs separately from the execution environment. Each subagent under a manager Devin gets its own isolated box (full VM, not just a container — needed for Docker-in-Docker and real app testing). Secrets live on the machine, never in the brain, so an unpredictable model cannot leak them. Feedback comes from CI rather than from replicating a local dev environment.
  - *Reported results:* Self-reported production numbers: Devin merged PRs up 7x; Devin authored 16% of commits in Jan 2026 rising to 80% by Mar 2026 across Cognition's own repos. Also a strong negative finding: pure auto-merge without review decays a codebase in roughly two weeks (button implementations scattered across 10 locations). Typical responsible spend $1,000-$5,000 per engineer per year.
  - *Source:* https://www.latent.space/p/cognition

---

## Sweep 2

**Angle.** GitHub-first: raw prompt/code artifacts for planner and implementer agents, fetched as raw files rather than read about in articles. Covers (a) shipping harness source (Roo Code `DEFAULT_MODES`, Aider's ArchitectCoder/ArchitectPrompts, Cline), (b) extracted/leaked first-party prompts (Claude Code's Plan subagent + delegation guidance via Piebald extraction; Traycer, Kiro, Antigravity, Cursor via x1xhlol), (c) artifact-chain frameworks (github/spec-kit), (d) curated subagent collections (wshobson/agents, VoltAgent, contains-studio), and (e) one battle-tested in-repo pipeline (humanlayer/humanlayer `.claude/commands/`). Emphasis on output contracts, handoff mechanics, tool restriction, and honest separation of benchmarked vs. merely-popular.

### Sources (21)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | Aider's architect/editor benchmark post on the 133-exercise Exercism benchmark. Sept 2024 — old (pre-reasoning-model-era), and the model pairs benchmarked (o1-preview/o1-mini/GPT-4o) are all retired. Treat the mechanism as validated, the numbers as stale. | https://aider.chat/2024/09/26/architect.html |
| `peer-reviewed-or-benchmarked` | Anthropic's own writeup of the orchestrator-subagent research system, with an internal eval number AND an explicit disclaimer that the pattern transfers poorly to coding. | https://www.anthropic.com/engineering/multi-agent-research-system |
| `primary-official` | Aider's ArchitectPrompts — the entire architect system prompt is 7 lines. Paired with architect_coder.py which shows the mechanical handoff to the editor model. | https://raw.githubusercontent.com/Aider-AI/aider/main/aider/coders/architect_prompts.py |
| `primary-official` | Roo Code's DEFAULT_MODES array — the literal shipping roleDefinition + customInstructions + tool `groups` for Architect, Code, Ask, Debug, and Orchestrator (Boomerang) modes. 24k stars. | https://raw.githubusercontent.com/RooCodeInc/Roo-Code/main/packages/types/src/mode.ts |
| `primary-official` | Roo Code's `new_task` delegation tool schema — the mechanism behind boomerang subtasks. | https://raw.githubusercontent.com/RooCodeInc/Roo-Code/main/src/core/prompts/tools/native-tools/new_task.ts |
| `primary-official` | Mechanically extracted, per-version dump of Claude Code's system prompt fragments, subagent prompts (Plan/Explore/general-purpose), and tool descriptions. 12k stars, updated through v2.1.219 (July 2026). Third-party extraction of first-party text — anyone with the CLI can verify it, but Anthropic has not published it. | https://github.com/Piebald-AI/claude-code-system-prompts |
| `primary-official` | GitHub's spec-driven development kit. 124k stars, pushed the day of this research. templates/commands/{specify,plan,tasks,implement,analyze}.md define a hard artifact chain: spec.md → plan.md → tasks.md → code, plus a read-only cross-artifact consistency auditor. | https://github.com/github/spec-kit |
| `primary-official` | The strictest task-format contract I found anywhere: a mandatory `- [ ] [TaskID] [P?] [Story?] Description with file path` grammar with explicit ✅/❌ examples. | https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/tasks.md |
| `primary-official` | Cline's team/subagent prompt builder. Notable for what it does NOT contain: no canned orchestrator persona. The spawner's prompt is injected as `# Team Teammate Role\n{prompt}` rules, or as a full `overridePrompt`. 65k stars, pushed same day. | https://raw.githubusercontent.com/cline/cline/main/sdk/packages/core/src/extensions/tools/team/subagent-prompts.ts |
| `practitioner-battle-tested` | HumanLayer's in-repo research_codebase.md / create_plan.md / implement_plan.md / validate_plan.md command chain — the artifacts actually used on their own 100k+ LOC product. 11k stars. Last pushed June 2026. | https://github.com/humanlayer/humanlayer/tree/main/.claude/commands |
| `practitioner-battle-tested` | The evidence claim behind the above: 35k LOC shipped to BAML (300k-LOC Rust codebase) in ~7 hours, context utilization kept at 40-60%, and a paired A/B anecdote where the researched plan was merged and the unresearched one was not. Vendor self-report, n≈small, no controls. | https://www.humanlayer.dev/blog/advanced-context-engineering |
| `practitioner-battle-tested` | 38k stars, 203 agents / 175 skills across 94 plugins, pushed within the week. Distinguished from the slop repos by having actual machinery: `make validate STRICT=1`, drift detection, a plugin-eval pytest suite, real-CLI smoke tests, and a name-collision checker in CI. Contains three separate planner/implementer pairs (agent-teams, ship-mate, conductor). | https://github.com/wshobson/agents |
| `practitioner-battle-tested` | team-lead.md + team-implementer.md: an orchestrator/implementer pair built entirely around exclusive file ownership as the conflict-avoidance primitive. | https://raw.githubusercontent.com/wshobson/agents/main/plugins/agent-teams/agents/team-lead.md |
| `practitioner-battle-tested` | The authoring spec behind those agents: required frontmatter per file type, mandatory trigger phrases in `description`, a 'talk about actions, not tools' portability rule, globally-unique agent naming, model-tier aliases. This is the closest thing to a written convention standard for subagent files. | https://raw.githubusercontent.com/wshobson/agents/main/docs/authoring.md |
| `practitioner-battle-tested` | ship-mate: orchestrate.md → architect.md → implement.md, coordinated through `.claude/pipeline/state.json` checkpoints and three markdown handoff files. A complete, readable plan→implement pipeline in ~250 lines total. | https://raw.githubusercontent.com/wshobson/agents/main/plugins/ship-mate/agents/architect.md |
| `popular-but-unvalidated` | 23.8k stars, 100+ agents including a 09-meta-orchestration category. Content is keyword-salad: hundreds of noun-phrase bullets, unfalsifiable 'checklists' like 'Performance optimal consistently'. The `multi-agent-coordinator` agent's frontmatter grants `tools: Read, Write, Edit, Glob, Grep` — no Task/Agent tool — so it structurally cannot delegate to anything. | https://github.com/VoltAgent/awesome-claude-code-subagents |
| `popular-but-unvalidated` | 12.4k stars. Last commit 2025-07-28 — dead for a full year. 38 role-flavored agents (rapid-prototyper, whimsy-injector, studio-producer) with zero planner/orchestrator and no delegation mechanism at all. A role catalog, not a workflow. | https://github.com/contains-studio/agents |
| `unverified` | Traycer AI's plan-mode system prompt + the `write_phases` / `hand_over_to_approach_agent` tool schemas (phase_mode_tools.json, plan_mode_tools.json). Traycer is a planning-only commercial product, so its planner prompt is the whole product. Dated Aug 2025 in-prompt. | https://raw.githubusercontent.com/x1xhlol/system-prompts-and-models-of-ai-tools/main/Traycer%20AI/plan_mode_prompts |
| `unverified` | AWS Kiro's spec workflow prompt: requirements.md (EARS format) → design.md → tasks.md, each gated on explicit user approval, with a hard exclusion list of non-coding tasks and `_Requirements: 1.1_` back-references on every task. | https://raw.githubusercontent.com/x1xhlol/system-prompts-and-models-of-ai-tools/main/Kiro/Spec_Prompt.txt |
| `unverified` | Google Antigravity's PLANNING/EXECUTION/VERIFICATION mode prompt with a fully specified implementation_plan.md format (per-file [MODIFY]/[NEW]/[DELETE] headings, Verification Plan split into automated commands vs manual steps) plus task.md and walkthrough.md artifacts. | https://raw.githubusercontent.com/x1xhlol/system-prompts-and-models-of-ai-tools/main/Google/Antigravity/planning-mode.txt |
| `unverified` | Cursor's agent prompt — the counter-position: no planner agent, no plan file, a strict in-context todo_write spec instead. Useful as a control. | https://raw.githubusercontent.com/x1xhlol/system-prompts-and-models-of-ai-tools/main/Cursor%20Prompts/Agent%20Prompt%202025-09-03.txt |

### Verbatim prompt excerpts (30)

**Aider — aider/coders/architect_prompts.py (entire main_system prompt)**

```
Act as an expert architect engineer and provide direction to your editor engineer.
Study the change request and the current code.
Describe how to modify the code to complete the request.
The editor engineer will rely solely on your instructions, so make them unambiguous and complete.
Explain all needed code changes clearly and completely, but concisely.
Just show the changes needed.

DO NOT show the entire updated function/file/etc!
```

> Seven lines, and it is the only planner prompt in this report with a published benchmark behind it. 'will rely solely on your instructions' is literally true here — architect_coder.py clears the editor's message history before running it. Note also 'Just show the changes needed / DO NOT show the entire updated function': the architect is forbidden from writing the code, which is what keeps the roles from collapsing.

**Aider — aider/coders/architect_coder.py (the handoff mechanics, not a prompt)**

```
editor_coder = Coder.create(**new_kwargs)
editor_coder.cur_messages = []
editor_coder.done_messages = []
...
kwargs["edit_format"] = self.main_model.editor_edit_format
kwargs["suggest_shell_commands"] = False
kwargs["map_tokens"] = 0
```

> The most important artifact in this report and it contains no prose. The implementer gets zero chat history, zero repo map, and no shell suggestions — only the architect's text plus the in-chat file contents. Any planner prompt you write should be tested against this assumption: if the plan is unreadable with the conversation deleted, it is broken.

**Aider — aider/coders/editor_editblock_prompts.py (the entire editor system prompt)**

```
Act as an expert software developer who edits source code.
{final_reminders}
Describe each change with a *SEARCH/REPLACE block* per the examples below.
All changes to files must use this *SEARCH/REPLACE block* format.
ONLY EVER RETURN CODE IN A *SEARCH/REPLACE BLOCK*!

    shell_cmd_prompt = ""
    no_shell_cmd_prompt = ""
    shell_cmd_reminder = ""
    go_ahead_tip = ""
    rename_with_shell = ""
```

> The implementer prompt is defined largely by deletion — the subclass blanks five inherited sections to empty strings. An implementer that already has a plan needs less prompt, not more: no shell guidance, no proactivity tips, no 'go ahead' framing. Just the edit format.

**Roo Code — packages/types/src/mode.ts, Orchestrator mode customInstructions**

```
For each subtask, use the `new_task` tool to delegate. Choose the most appropriate mode for the subtask's specific goal and provide comprehensive instructions in the `message` parameter. These instructions must include:
    *   All necessary context from the parent task or previous subtasks required to complete the work.
    *   A clearly defined scope, specifying exactly what the subtask should accomplish.
    *   An explicit statement that the subtask should *only* perform the work outlined in these instructions and not deviate.
    *   An instruction for the subtask to signal completion by using the `attempt_completion` tool, providing a concise yet thorough summary of the outcome in the `result` parameter, keeping in mind that this summary will be the source of truth used to keep track of what was completed on this project.
    *   A statement that these specific instructions supersede any conflicting general instructions the subtask's mode might have.
```

> A five-item required checklist for every delegation message, from shipping source. The fifth item is the one nobody thinks of: subagents carry their own mode/role prompt that can conflict with the task, so precedence must be stated. The fourth turns the return summary into a durable project record rather than a throwaway.

**Roo Code — packages/types/src/mode.ts, Orchestrator mode `groups`**

```
{
		slug: "orchestrator",
		name: "🪃 Orchestrator",
		...
		groups: [],
```

> The Orchestrator has an empty tool-group array. It cannot read, edit, run commands, or use MCP — only the always-available tools plus `new_task`. Compare to VoltAgent's 'multi-agent-coordinator' which has Read/Write/Edit/Glob/Grep and no delegation tool: exactly inverted. If you want an agent that only orchestrates, take away its hands.

**Roo Code — packages/types/src/mode.ts, Architect mode**

```
groups: ["read", ["edit", { fileRegex: "\\.md$", description: "Markdown files only" }], "mcp"],
...
Each todo item should be:
   - Specific and actionable
   - Listed in logical execution order
   - Focused on a single, well-defined outcome
   - Clear enough that another mode could execute it independently
...
**IMPORTANT: Focus on creating clear, actionable todo lists rather than lengthy markdown documents.**
**CRITICAL: Never provide level of effort time estimates (e.g., hours, days, weeks) for tasks.**
```

> Three separate mechanisms in one mode: a regex-scoped write permission (markdown only), a four-property definition of a good plan item whose last clause is the handoff test ('Clear enough that another mode could execute it independently'), and a hard ban on time estimates. Also note the anti-verbosity push — the planner is told to prefer a todo list over a document.

**Claude Code — system-prompt-writing-subagent-prompts.md (v2.1.176), extracted**

```
Any agent other than a fork starts with zero context. Brief the agent like a smart colleague who just walked into the room — it hasn't seen this conversation, doesn't know what you've tried, doesn't understand why this task matters.
- Explain what you're trying to accomplish and why.
- Describe what you've already learned or ruled out.
- Give enough context about the surrounding problem that the agent can make judgment calls rather than just following a narrow instruction.
- If you need a short response, say so ("report in under 200 words").
- Lookups: hand over the exact command. Investigations: hand over the question — prescribed steps become dead weight when the premise is wrong.

For fresh agents, terse command-style prompts produce shallow, generic work.

**Never delegate understanding.** Don't write "based on your findings, fix the bug" or "based on the research, implement it." Those phrases push synthesis onto the agent instead of doing it yourself. Write prompts that prove you understood: include file paths, line numbers, what specifically to change.
```

> The single densest passage I found. Four distinct rules in one block: the cold-start framing, the deliberate over-briefing ('so the agent can make judgment calls'), the lookup-vs-investigation split, and 'Never delegate understanding' — which is the sharpest available statement of what makes a planner/implementer split fail. Nearly every line here converts directly into a line of a planner system prompt.

**Claude Code — agent-prompt-plan-mode-enhanced.md (v2.1.118) frontmatter + prohibition block, extracted**

```
agentMetadata:
  agentType: "Plan"
  disallowedTools: ["Agent", "Artifact", "ExitPlanMode", "Edit", "Write", "NotebookEdit"]
  whenToUse: "Software architect agent for designing implementation plans..."
---
=== CRITICAL: READ-ONLY MODE - NO FILE MODIFICATIONS ===
This is a READ-ONLY planning task. You are STRICTLY PROHIBITED from:
- Creating new files (no Write, touch, or file creation of any kind)
- Creating temporary files anywhere, including /tmp
- Using redirect operators (>, >>, |) or heredocs to write to files
- Running ANY commands that change system state
...
   - Use Bash ONLY for read-only operations (ls, git status, git log, git diff, find, cat, head, tail)
   - NEVER use Bash for: mkdir, touch, rm, cp, mv, git add, git commit, npm install, pip install
```

> Read-only enforced twice — allowlist plus prose — and the prose closes the shell holes the allowlist can't (`>`, heredocs, /tmp). The permitted/forbidden Bash verb lists are directly liftable. Note `disallowedTools` includes `Agent`: the planner cannot spawn further subagents.

**Claude Code — agent-prompt-plan-mode-enhanced.md, required output section**

```
## Required Output

End your response with:

### Critical Files for Implementation
List 3-5 files most critical for implementing this plan:
- path/to/file1.ts
- path/to/file2.ts
- path/to/file3.ts
```

> A mandated, bounded, machine-parseable tail. 3-5 is a real number, not 'the relevant files'. This is the minimum viable output contract for a planner: whatever else the plan says, the caller can always extract a file list.

**Claude Code — system-prompt-phase-four-of-plan-mode.md (v2.1.219), extracted**

```
### Phase 4: Final Plan
Goal: Write your final plan to the plan file (the only file you can edit).
- Begin with a **Context** section: explain why this change is being made — the problem or need it addresses, what prompted it, and the intended outcome
- Include only your recommended approach, not all alternatives
- Ensure that the plan file is concise enough to scan quickly, but detailed enough to execute effectively
- Name the critical files to be modified. For changes that repeat a pattern across many files, describe the pattern once and list a few representative paths — do not enumerate every file or line number
- Reference existing functions and utilities you found that should be reused, with their file paths
- Include a verification section describing how to test the changes end-to-end (run the code, use MCP tools, run tests)
```

> Six lines that fully specify a plan file, including two exceptions most templates miss: prune alternatives from the final artifact (they belong in the design phase), and don't enumerate repeated changes. 'Reference existing functions and utilities you found that should be reused, with their file paths' is the anti-reinvention clause.

**Claude Code — system-prompt-subagent-delegation-restraint.md (v2.1.215), extracted**

```
Subagents multiply cost and time: each one re-establishes context, re-explores, and reports back, and you then re-read its report. Delegate only when the payoff clearly exceeds that overhead. Before spawning, apply these tests:

- Do the work inline when it is a small, bounded sub-task — a few file reads, one search, a short edit, a single check.
- Do not fan out multiple subagents on a single small task. Parallel subagents are for genuinely independent, sizeable tracks (unrelated modules, a wide multi-file investigation), not for splitting one modest job into pieces.
- Do not spawn a subagent to review, re-verify, or double-check work you can verify inline. Verification that fits in your own loop belongs in your own loop.
- If you delegate, commit to the delegation: do not redo the subagent's work while waiting, and do not re-derive its findings once it reports. If you find yourself repeating what a subagent is doing, you should not have spawned it.
- Keep spawn counts low. One well-briefed subagent for a large independent chunk is worth more than several loosely-briefed ones; brief it precisely the first time rather than launching, waiting, and re-briefing.
```

> Almost no community orchestrator prompt contains a restraint clause; this one is 100% restraint. The last bullet — brief once, precisely, rather than launch/wait/re-brief — is the practical counterweight to 'spawn agents in parallel' advice.

**Claude Code — agent-prompt-coordinator-worker-instructions.md (v2.1.217), extracted**

```
You are a worker agent executing a task assigned by the coordinator.

## Environment
- Other workers may be making changes on this branch. If you encounter confusing file state, unexpected changes, or merge conflicts that aren't from your work, stop and report to the coordinator rather than trying to resolve it yourself... Don't modify code you don't understand.

## Scope
Complete exactly what was asked. Don't fix unrelated issues you discover — suggest them as follow-ups instead.
- If you changed any files, commit your changes when done... Only stage files you actually changed — never use `git add .` or `git add -A`. Report the commit hash in your summary.

## When Things Go Wrong
- If the task is ambiguous, pick the most likely interpretation and note your assumption
- Don't retry the same failed approach more than once

## Output
Your response goes directly to the coordinator (not the user)...
1. **What you did or found** — be specific with file paths, line numbers, code snippets
2. **Summary:** One sentence the coordinator can relay to the user

Good summary: "Added Redis cache implementation. Tests pass, typecheck clean. Committed abc123."
Bad summary: "I looked at files X, Y, and Z. Y has the changes you mentioned."
```

> The best implementer prompt in this report. Every clause is concrete: the shared-branch stop condition, `never use git add .` (because a parallel worker's files would get swept in), 'pick the most likely interpretation and note your assumption' instead of blocking, retry cap of one, and a good/bad summary pair that teaches outcome-reporting over activity-reporting. 'Your response goes directly to the coordinator (not the user)' fixes the audience explicitly.

**HumanLayer — .claude/commands/create_plan.md, plan template success criteria**

```
### Success Criteria:

#### Automated Verification:
- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `npm run typecheck`
- [ ] Linting passes: `make lint`
- [ ] Integration tests pass: `make test-integration`

#### Manual Verification:
- [ ] Feature works as expected when tested via UI
- [ ] Performance is acceptable under load
- [ ] Edge case handling verified manually
- [ ] No regressions in related features

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.
```

> The command is inside the checkbox. This is what makes the downstream validate_plan.md pass possible — it re-runs each Automated Verification command against the actual repo and reports Fully/Partially implemented per phase. The elsewhere-stated rule 'automated steps should use `make` whenever possible' makes the commands stable across directories.

**HumanLayer — .claude/commands/create_plan.md, guidelines**

```
1. **Read all mentioned files immediately and FULLY**... **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files. **CRITICAL**: DO NOT spawn sub-tasks before reading these files yourself in the main context. **NEVER** read files partially...

1. **If the user corrects any misunderstanding**: DO NOT just accept the correction. Spawn new research tasks to verify the correct information... Only proceed once you've verified the facts yourself.

6. **No Open Questions in Final Plan**: If you encounter open questions during planning, STOP. Research or ask for clarification immediately.

Only ask questions that you genuinely cannot answer through code investigation.
```

> Four rules that are unusual and load-bearing. Read files fully before delegating (so the orchestrator isn't reasoning off partial context). Verify user corrections in code rather than accepting them (the planner is told to distrust its principal). Zero open questions in the artifact. And a filter on questions — only ask what code cannot answer — which is what stops the 'ask 12 clarifying questions' failure mode.

**HumanLayer — .claude/commands/implement_plan.md**

```
Plans are carefully designed, but reality can be messy. Your job is to:
- Follow the plan's intent while adapting to what you find
...
If you encounter a mismatch:
- STOP and think deeply about why the plan can't be followed
- Present the issue clearly:
  ```
  Issue in Phase [N]:
  Expected: [what the plan says]
  Found: [actual situation]
  Why this matters: [explanation]

  How should I proceed?
  ```
...
Use sub-tasks sparingly - mainly for targeted debugging or exploring unfamiliar territory.

do not check off items in the manual testing steps until confirmed by the user.

If the plan has existing checkmarks:
- Trust that completed work is done
- Pick up from the first unchecked item
```

> A four-field deviation report format (Expected / Found / Why this matters / How should I proceed) — structured enough to act on, short enough that the model will actually emit it. Plus resumability: the plan file's checkboxes are the durable progress state, so a fresh implementer session can resume without any conversation history. And the implementer is told to delegate sparingly — the fan-out belongs in the planning phase.

**github/spec-kit — templates/commands/tasks.md, Checklist Format (REQUIRED)**

```
Every task MUST strictly follow this format:

- [ ] [TaskID] [P?] [Story?] Description with file path

**Examples**:
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)
...
**[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
...
The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.
```

> A formal grammar with negative examples, which is far more effective than an adjective. The `[P]` marker's definition — 'different files, no dependencies on incomplete tasks' — is the parallelism decision reduced to a mechanical test. The last line is the design goal of the whole planner/implementer split stated in one sentence.

**github/spec-kit — templates/commands/analyze.md, detection passes**

```
**STRICTLY READ-ONLY**: Do not modify any files. Output a structured analysis report.

**Constitution Authority**: The project constitution is **non-negotiable**... Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle.

#### B. Ambiguity Detection
- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`)

#### C. Underspecification
- Requirements with verbs but missing object or measurable outcome
- Tasks referencing files or components not defined in spec/plan

#### E. Coverage Gaps
- Requirements with zero associated tasks
- Tasks with no mapped requirement/story

#### F. Inconsistency
- Terminology drift (same concept named differently across files)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)
```

> A plan-quality checklist you can run as a separate agent, in both directions (uncovered requirements AND orphan tasks). The named vague adjectives — fast, scalable, secure, intuitive, robust — are exactly the words that make a spec unimplementable, and listing them beats saying 'avoid vagueness'.

**Traycer AI — phase_mode_tools.json, `write_phases` schema and doctrine**

```
"promptForAgent": "A crisp and to the point prompt that AI agents can use to implement this phase. Do mention any relevant components, modules or folders in the codebase and make sure to enclose them backticks. Use markdown formatting. The prompt should be in 3-4 points and under 60 words."
"referredFiles": "Absolute file paths that should be referred by the agent to implement this phase."

[description] break any sizeable coding task—refactor or new feature—into *independently executable phases* that **always leave the codebase compiling and all tests green**.
* Treat each phase like a well-scoped pull request: one coherent chunk of work that reviewers can grasp at a glance.
1. **Shadow, don't overwrite** — Introduce parallel symbols (e.g., `Thing2`) instead of modifying the legacy implementation. Keep the original path alive and functional until the final "cut-over" phase.
2. **Phase-by-phase integrity** — Every phase must compile, run existing tests... For example, if an API's return type changes, update all its consumers in the same phase.
```

> A plan expressed as a typed tool call rather than markdown, with a hard word budget on the per-phase implementer prompt (60 words, 3-4 points) and absolute file paths as a required field. The 'shadow, don't overwrite' rule and the phase-integrity rule are the two concrete tests that decide phase boundaries — far more actionable than 'break it into logical steps'.

**Traycer AI — plan_mode_tools.json, `hand_over_to_approach_agent`**

```
"targetRole": "How much exploration is needed before drafting a file by file plan. planner: The task is very small and direct, no more exploration is needed at all and a full file by file plan can be proposed now; architect: approach and more detailed exploration is needed before writing the file by file plan; engineering_team: the task is very large and may require a multi-faceted analysis, involving a complex interaction between various components, before the approach can be written and a file by file plan can be made."
"reason": "The rationale for the chosen targetRole, explaining why this depth of exploration is appropriate."
```

> Explicit triage of planning depth, with a required written justification. The only artifact I found that treats 'how much planning does this need' as a first-class decision rather than a fixed pipeline. Worth copying if your planner will be invoked on both one-liners and multi-week features.

**Traycer AI — plan_mode_prompts (role framing)**

```
You are a highly respected technical lead of a large team. Your job is to provide a high-level design instead of a literal implementation of the approach...

We are working in a read-only access mode with the codebase, so you can not suggest writing code.

As a lead, you DO NOT write code, but you may mention symbols, classes, and functions relevant to the task. Writing code is disrespectful for your profession.

As a lead, you do not want to leave a poor impression on your large team by doing low-effort work, such as writing code or adding unnecessary extra tasks outside the user's task.

Aspects where certainty is lacking, such as unit tests, should only be recommended if the user explicitly inquires about them or if there are references to them within the attached context.
```

> Aggressive social framing to hold the role boundary — 'Writing code is disrespectful for your profession' is a strange sentence that is clearly there because the model kept writing code. It also inverts the usual test-enthusiasm default: don't propose tests unless the user asked or the codebase already has them. Note the tension with the 'name exact paths' principle — 'may mention symbols, classes, and functions' is the line it draws between design and implementation.

**AWS Kiro — Spec_Prompt.txt, task list rules**

```
Convert the feature design into a series of prompts for a code-generation LLM that will implement each step in a test-driven manner... Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step. Focus ONLY on tasks that involve writing, modifying, or testing code.
...
- The model MUST ensure each task is actionable by a coding agent by following these guidelines:
- Tasks should involve writing, modifying, or testing specific code components
- Tasks should specify what files or components need to be created or modified
- Tasks should be concrete enough that a coding agent can execute them without additional clarification
- Tasks should be scoped to specific coding activities (e.g., "Implement X function" rather than "Support X feature")
- The model MUST explicitly avoid including the following types of non-coding tasks:
- User acceptance testing or user feedback gathering
- Deployment to production or staging environments
- Performance metrics gathering or analysis
- Running the application to test end to end flows. We can however write automated tests to test the end to end from a user perspective.
- User training or documentation creation
- Business process changes or organizational changes
```

> The clearest 'is this a valid task' test I found, stated twice — once positively ('Implement X function' not 'Support X feature') and once as an enumerated blocklist. The blocklist is directly liftable. Note the carve-out on e2e: writing the automated test is in scope, running the app manually is not.

**AWS Kiro — Spec_Prompt.txt, tasks.md example format**

```
- [ ] 2. Implement data models and validation
- [ ] 2.1 Create core data model interfaces and types
  - Write TypeScript interfaces for all data models
  - Implement validation functions for data integrity
  - _Requirements: 2.1, 3.3, 1.2_

- [ ] 2.2 Implement User model with validation
  - Write User class with validation methods
  - Create unit tests for User model validation
  - _Requirements: 1.2_
```

> The `_Requirements: N.N_` trailer on every leaf task is the cheapest possible traceability mechanism — no tooling required, greppable, and it makes the 'requirement with zero tasks' audit a two-line script. Also note the hard cap: 'a maximum of two levels of hierarchy'.

**Google Antigravity — planning-mode.txt, implementation_plan.md format**

```
## Proposed Changes

Group files by component (e.g., package, feature area, dependency layer) and order logically (dependencies first). Separate components with horizontal rules for visual clarity.

### [Component Name]
Summary of what will change in this component, separated by files. For specific files, Use [NEW] and [DELETE] to demarcate new and deleted files, for example:

#### [MODIFY] [file basename](file:///absolute/path/to/modifiedfile)
#### [NEW] [file basename](file:///absolute/path/to/newfile)
#### [DELETE] [file basename](file:///absolute/path/to/deletedfile)

## Verification Plan
Summary of how you will verify that your changes have the desired effects.

### Automated Tests
- Exact commands you'll run, browser tests using the browser tool, etc.

### Manual Verification
- Asking the user to deploy to staging and testing, verifying UI changes on an iOS app etc.

## User Review Required
Document anything that requires user review or clarification, for example, breaking changes or significant design decisions... **If there are no such items, omit this section entirely.**
```

> The plan's section headings ARE the file paths, tagged with the operation. That makes the plan diffable against the eventual change set. Independently converges on HumanLayer's automated/manual verification split — two teams that didn't copy each other. And 'omit this section entirely' if empty is a small anti-boilerplate rule most templates lack.

**wshobson/agents — plugins/agent-teams/agents/team-lead.md, file ownership rules**

```
## File Ownership Rules

1. **One owner per file** — Never assign the same file to multiple teammates
2. **Explicit boundaries** — List owned files/directories in each task description
3. **Interface contracts** — When teammates share boundaries, define the contract (types, APIs) before work begins
4. **Shared files** — If a file must be touched by multiple teammates, the lead owns it and applies changes sequentially
...
5. Refer to teammates by their actual spawned NAME, never by UUID or role alias
6. If a spawned name is suffixed to avoid a collision, use the suffixed name from config/Agent output for all messages and tasks
```

> Rule 4 is the one that matters and the one most parallel-agent designs omit: shared files escalate to the orchestrator rather than being negotiated between peers. Rules 5-6 are operational scar tissue about agent naming that only shows up once you actually run multi-agent teams.

**wshobson/agents — plugins/agent-teams/agents/team-implementer.md**

```
## File Ownership Protocol
1. **Only modify files assigned to you** — Check your task description for the explicit list of owned files/directories
2. **Never touch shared files** — If you need changes to a shared file, message the team lead
4. **Interface contracts are immutable** — Do not change agreed-upon interfaces without team lead approval
5. **If in doubt, ask** — Message the team lead before touching any file not explicitly in your ownership list

## Integration Points
2. **Don't implement their side** — Stub or mock their component during development

## Quality Standards
- Keep changes minimal — implement exactly what's specified
- No scope creep — if you see improvements outside your assignment, note them but don't implement
- Preserve existing comments and formatting in modified files
```

> The exact mirror of the lead's rules, restated from the worker's side — both halves of a contract have to carry it, because the implementer never sees the lead's prompt. "Don't implement their side — Stub or mock their component" is the specific instruction that prevents two parallel agents from both writing the same integration.

**wshobson/agents — plugins/agent-teams/skills/task-coordination-strategies/references/task-decomposition.md, task template**

```
## Task: {Stream Name}

### Objective
{1-2 sentence description of what to build}

### Owned Files
- {file1} — {purpose}

### Requirements
1. {Specific deliverable 1}

### Interface Contract
- Exports: {types/functions this stream provides}
- Imports: {types/functions this stream consumes from other streams}

### Acceptance Criteria
- [ ] {Verifiable criterion 1}

### Out of Scope
- {Explicitly excluded work}
```

> A six-section handoff schema with the two sections most templates drop: an explicit Exports/Imports interface contract, and Out of Scope. Paired in the same file with worked decompositions (auth split into login / registration / shared-types streams with a dependency graph), which is what makes the abstraction usable.

**wshobson/agents — plugins/ship-mate/agents/architect.md, escalation triggers and plan schema**

```
### 4. Check for Escalation Triggers
Before writing the plan, escalate to human if:
- This task requires external API contract modifications
- This task touches database schema in a way that affects existing data
- This task requires changes to the authentication or security model
- Implementation complexity significantly exceeds the original story scope
- There is insufficient information to produce a complete plan

If escalating, write a clear question to the human and halt. Do not guess.

## Files to Modify
| File path | What changes                  |

## Implementation Steps
Each step must be:
- Actionable without further clarification
- Referenced to a specific file path
- Consistent with the patterns in AGENTS.md
```

> Five named, checkable escalation triggers rather than 'escalate if unsure' — an agent can actually evaluate 'does this touch the auth model?'. The three-property test for a step ends with 'Referenced to a specific file path', which is the single most repeated planner requirement across every source in this report.

**wshobson/agents — plugins/ship-mate/agents/implement.md, deviation protocol and boundaries**

```
## Strict Boundaries
- Implement ONLY what is in the architect plan — no scope additions, no "while I'm here" changes
- Leave NO TODOs, NO commented-out code, NO debug logs (`console.log`, `print`, etc.)
- Do NOT add error handling for scenarios that cannot happen
- Do NOT add abstractions beyond what the task requires

### 2. Verify Plan Feasibility
Before implementing, check each step in the plan:
- Does each referenced file path exist?
- Does the described function/component/module exist where expected?
- Is there anything ambiguous or contradictory?

If a plan step is impossible or contradictory: **do not silently skip it**. Flag it:
⚠️  Plan deviation required:
    Step [N]: [original step]
    Issue: [what's wrong]
    Proposed adjustment: [your proposed fix]
    Proceeding with adjustment unless instructed otherwise.

- If any code touches authentication, authorisation, tokens, PII, CORS, or session management → halt immediately and flag to the reviewer before proceeding
```

> A pre-flight validation pass over the plan before any edit — 'does each referenced file path exist?' catches stale plans cheaply. The deviation block is non-blocking by default ('Proceeding with adjustment unless instructed otherwise'), which keeps autonomy while leaving an audit trail. And a named list of security surfaces that trigger a hard halt.

**Cursor — Agent Prompt 2025-09-03.txt, todo_spec (the no-planner counter-position)**

```
- Create atomic todo items (≤14 words, verb-led, clear outcome) using todo_write before you start working on an implementation task.
- Todo items should be high-level, meaningful, nontrivial tasks that would take a user at least 5 minutes to perform...
- Todo items should NOT include operational actions done in service of higher-level tasks.
- Don't cram multiple semantically different steps into one todo... Prefer fewer, larger todo items.
- If the user asks you to plan but not implement, don't create a todo list until it's actually time to implement.
- If the user asks you to implement, do not output a separate text-based High-Level Plan. Just build and display the todo list.
...
Gate before new edits: Before starting any new file or code edit, reconcile the TODO list via todo_write (merge=true): mark newly completed tasks as completed and set the next task to in_progress.
```

> Included as a control. The highest-volume coding agent in production ships no planner agent, no plan file, and no delegation — just a plan-as-state-in-context with a ≤14-word cap, a 5-minute-of-human-work floor, and an edit-time reconciliation gate. If your planner/implementer split can't beat this, it isn't earning its latency.

**wshobson/agents — docs/authoring.md, structural conventions**

```
| `agents/<name>.md` | Required: `name`, `description` | Recommended: `model`, optional `tools:`, optional `color:` |

**Description triggers.** Include a recognized phrase: `Use when …`, `Use this skill when …`, `Use PROACTIVELY when …`, `Use after …`, `Trigger when …`, `Auto-loads when …`. The `MISSING_TRIGGER` lint fires without one. The phrase is what the model uses to decide whether to invoke your skill/agent.

### Talk about actions, not tools
| "Use the `Read` tool to open the file." | "Open the file." |
| "Use `TodoWrite` to track progress." | "Track progress as you go." |
| "Spawn a subagent via the `Task` tool." | "Delegate to a subagent." |

### Use globally unique agent names
Claude Code keys installed agents by the YAML frontmatter `name`, so two plugins that ship the same agent name can silently overwrite each other when installed together.

Prefer stating goals over step-by-step scaffolding in fable-tier agent bodies
```

> The only written, CI-enforced convention standard I found for subagent files. Four things worth adopting verbatim: `description` must contain a literal trigger phrase (it is the routing signal, not documentation); actions not tool names for portability; globally unique names because collisions are silent; and the altitude rule — higher-capability models want goals, not scaffolding.

### Approaches (11)

- **Architect/Editor split with a deliberately amnesiac editor (Aider)** — Two models, two roles, one turn. The architect gets the repo map and full chat history and is told: "Act as an expert architect engineer and provide direction to your editor engineer... The editor engineer will rely solely on your instructions, so make them unambiguous and complete... Just show the changes needed. DO NOT show the entire updated function/file/etc!" Its prose reply is then fed verbatim as the user message to a second Coder instance. The critical part is in architect_coder.py, not the prompt: the editor is constructed with `editor_coder.cur_messages = []`, `editor_coder.done_messages = []`, `map_tokens = 0`, `suggest_shell_commands = False`, `cache_prompts = False`. The implementer therefore starts with literally zero conversation history and no repo map — only the architect's prose plus the raw contents of the in-chat files. The editor's own system prompt is stripped to almost nothing: "Act as an expert software developer who edits source code... ONLY EVER RETURN CODE IN A *SEARCH/REPLACE BLOCK*!" All shell-command, reminder, and tip sections are blanked to empty strings. A human confirm gate ("Edit the files?") sits between the two unless auto_accept_architect is set.
  - *Reported results:* Benchmarked on Aider's 133-problem Exercism benchmark. o1-preview+o1-mini and o1-preview+deepseek hit 85.0% vs 79.7% for o1-preview solo. Claude 3.5 Sonnet self-paired 80.5% vs 77.4% solo (+3.1); GPT-4o 75.2% vs 71.4% (+3.8); o1-mini 71.4% vs 61.1% (+10.3). Author's mechanism claim: "the model has to split its attention between solving the coding problem and conforming to the edit format." CAVEAT: September 2024. Every benchmarked model is retired, and modern models are far better at edit formats, so the specific gains almost certainly do not replicate. The architectural insight (context isolation + role separation) is what survives, not the numbers.
  - *Source:* https://github.com/Aider-AI/aider/blob/main/aider/coders/architect_coder.py
- **Boomerang subtask delegation (Roo Code Orchestrator mode)** — The Orchestrator mode is defined with `groups: []` — it has NO read, edit, command, or MCP tools whatsoever. Its only capability is `new_task`, which spawns a fresh task in a chosen mode. Its customInstructions enumerate five mandatory contents for every delegation message: (1) all necessary context from the parent task, (2) a clearly defined scope, (3) "An explicit statement that the subtask should *only* perform the work outlined in these instructions and not deviate", (4) an instruction to finish with `attempt_completion` whose `result` summary "will be the source of truth used to keep track of what was completed on this project", and (5) "A statement that these specific instructions supersede any conflicting general instructions the subtask's mode might have." The subtask's full transcript never returns to the orchestrator — only the `result` summary does. The Architect mode is a separate thing: `groups: ["read", ["edit", {fileRegex: "\\.md$"}], "mcp"]` — read-only except markdown, so it can write a plan file and nothing else, and it ends by calling `switch_mode` to ask the user to move to Code mode.
  - *Reported results:* None reported. No benchmark, no A/B, no published outcome data — despite 24k stars and heavy blog coverage. The `new_task` tool carries one operational fix learned the hard way: "CRITICAL: This tool MUST be called alone. Do NOT call this tool alongside other tools in the same message turn."
  - *Source:* https://github.com/RooCodeInc/Roo-Code/blob/main/packages/types/src/mode.ts
- **Read-only Plan subagent with a hard file-write prohibition and a mandated tail section (Claude Code)** — Claude Code ships a `Plan` subagent whose agentMetadata sets `disallowedTools: [Agent, Artifact, ExitPlanMode, Edit, Write, NotebookEdit]` — belt — and whose prompt then re-states the prohibition in prose — braces. It bans not just Edit/Write but "Using redirect operators (>, >>, |) or heredocs to write to files" and "Creating temporary files anywhere, including /tmp", and enumerates permitted Bash verbs (ls, git status, git log, git diff, find, cat, head, tail) against forbidden ones (mkdir, touch, rm, cp, mv, git add, git commit, npm install, pip install). The prompt ends with a mandated output section: "### Critical Files for Implementation — List 3-5 files most critical for implementing this plan." Interactive plan mode is a separate 5-phase loop: Phase 1 fan out up to N Explore subagents in parallel ("you should try to use the minimum number of agents necessary (usually just 1)"); Phase 2 design; Phase 3 review by reading the critical files identified during exploration; Phase 4 write the plan file — the ONLY writable file; Phase 5 call ExitPlanMode for approval.
  - *Reported results:* No public benchmark for the plan-mode split specifically. Version-tracked behavior changes (through v2.1.219) are the only visible signal that it is being iterated on in production. Anthropic's one published multi-agent number (90.2% over single-agent) is for research tasks and comes with an explicit anti-transfer caveat for coding.
  - *Source:* https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/agent-prompt-plan-mode-enhanced.md
- **Exclusive file ownership as the parallelism primitive (wshobson agent-teams)** — team-lead decomposes into vertical slices and assigns each teammate a literal list of owned file paths. Four rules govern it: one owner per file, boundaries listed explicitly in the task description, interface contracts (shared types) defined before work begins, and — the interesting one — "If a file must be touched by multiple teammates, the lead owns it and applies changes sequentially." The mirror-image team-implementer enforces the same from the other side: "Never touch shared files — If you need changes to a shared file, message the team lead" and "Interface contracts are immutable — Do not change agreed-upon interfaces without team lead approval." The supporting skill reference shows worked decompositions (auth feature split into login / registration / shared-types-and-middleware streams, with a dependency graph) and a task template whose required sections are Objective / Owned Files / Requirements / Interface Contract (Exports + Imports) / Acceptance Criteria / Out of Scope. The lead's tool grant actually includes TeamCreate, TaskCreate, TaskUpdate, SendMessage, Agent — it can genuinely delegate.
  - *Reported results:* No outcome evidence. The repo has real CI (structural validation, drift gates, plugin-eval pytest, real-CLI smoke tests) that proves the files are well-formed and installable across five harnesses, but nothing that measures whether the ownership discipline improves results. Structural quality is validated; behavioral quality is not.
  - *Source:* https://github.com/wshobson/agents/blob/main/plugins/agent-teams/agents/team-lead.md
- **Artifact chain with a cross-artifact consistency auditor (github/spec-kit)** — Four commands, four files, strict ordering: /specify → spec.md; /plan → plan.md + research.md + data-model.md + contracts/ + quickstart.md; /tasks → tasks.md; /implement → code. Each command reloads the constitution (`/memory/constitution.md`) plus every upstream artifact. tasks.md is organized by user story (P1, P2...) not by layer, so each phase is an independently testable increment. The distinctive piece is /analyze: a STRICTLY READ-ONLY pass that runs after /tasks and before /implement, builds a requirements inventory keyed on FR-###/SC-### identifiers, builds a task→requirement coverage map, and reports Requirements with zero associated tasks and Tasks with no mapped requirement, plus severity-graded findings (constitution MUST violations are automatically CRITICAL). /implement additionally gates on checklist completion and STOPs to ask before proceeding if any checklist has incomplete items.
  - *Reported results:* None reported. 124k stars and daily commits, but no published evaluation that the spec chain produces better code than not using it. The `lean` preset (5 commands, ~15 lines each) existing alongside the full templates (~250 lines each) suggests the maintainers themselves are unsure how much ceremony is load-bearing — that is itself a finding.
  - *Source:* https://github.com/github/spec-kit/blob/main/templates/commands/analyze.md
- **Automated-vs-manual verification split in the plan file (HumanLayer)** — create_plan.md prescribes a plan template where every phase carries a Success Criteria block that is explicitly bifurcated. "#### Automated Verification:" holds checkboxes each containing a runnable command (`- [ ] Type checking passes: npm run typecheck`), with the additional rule that "automated steps should use `make` whenever possible." "#### Manual Verification:" holds things a human must eyeball. implement_plan.md then reads that same file, runs the automated block, checks off boxes in the plan file itself via Edit, and hard-stops: "After completing all automated verification for a phase, pause and inform the human that the phase is ready for manual testing... do not check off items in the manual testing steps until confirmed by the user." A fourth command, validate_plan.md, re-derives implementation from `git log`/`git diff`, re-executes every Automated Verification command, and emits a per-phase Fully/Partially implemented report. The plan template also mandates a "## What We're NOT Doing" section and a hard rule: "No Open Questions in Final Plan — If you encounter open questions during planning, STOP."
  - *Reported results:* The strongest practitioner evidence I found, and still weak by scientific standards: 35k LOC shipped into BAML (a 300k-LOC Rust codebase the team was unfamiliar with) as two draft PRs in ~7 hours for work estimated at 3-5 days each; context utilization deliberately held at 40-60%; ~$12k/month Opus spend for a team of three. Plus a single paired comparison where a plan built with a research phase was merged and the one without it was not. Vendor self-report, no controls, n=1 codebase.
  - *Source:* https://github.com/humanlayer/humanlayer/blob/main/.claude/commands/create_plan.md
- **Structured plan as a tool-call schema rather than free markdown (Traycer)** — Instead of asking for markdown, Traycer forces the plan through a JSON tool schema. `write_phases` requires an array of phases, each with `{id, title, promptForAgent, referredFiles}` where `promptForAgent` is spec'd as "A crisp and to the point prompt that AI agents can use to implement this phase... The prompt should be in 3-4 points and under 60 words" and `referredFiles` is "Absolute file paths that should be referred by the agent to implement this phase." The tool description carries the phase-sizing doctrine: "Treat each phase like a well-scoped pull request", plus "Shadow, don't overwrite — Introduce parallel symbols (e.g., Thing2) instead of modifying the legacy implementation" and "Every phase must compile, run existing tests". Separately, plan mode's `hand_over_to_approach_agent` tool routes by required exploration depth via an enum — `planner` (small and direct, write the file-by-file plan now), `architect` (needs more exploration first), `engineering_team` (multi-faceted analysis needed) — with a required `reason` field justifying the choice.
  - *Reported results:* None reported. Leaked prompt, no vendor benchmark, no independent evaluation. Its value here is purely as a design artifact from a company whose entire product is the planner.
  - *Source:* https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools/blob/main/Traycer%20AI/phase_mode_tools.json
- **Approval-gated three-document spec chain with requirement back-references (AWS Kiro)** — requirements.md (in EARS format, hierarchically numbered) → design.md → tasks.md, with a `userInput` tool call carrying an exact literal reason string (`spec-requirements-review`, `spec-design-review`, `spec-tasks-review`) after each document, and a rule that "The model MUST NOT proceed to the design document until receiving clear approval." tasks.md is capped at two levels of hierarchy with decimal numbering, and every task ends with an italic back-reference to the requirement IDs it satisfies (`_Requirements: 2.1, 3.3, 1.2_`). The prompt carries an explicit blocklist of things that may not appear as tasks: user acceptance testing, deployment, performance metrics gathering, "Running the application to test end to end flows", training, documentation, business process changes. The whole workflow terminates at the artifact: "This workflow is ONLY for creating design and planning artifacts. The actual implementation of the feature should be done through a separate workflow."
  - *Reported results:* None reported. Leaked prompt from a commercial product.
  - *Source:* https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools/blob/main/Kiro/Spec_Prompt.txt
- **Mode-as-state-machine with per-file-operation plan headings (Google Antigravity)** — One agent, three declared modes (PLANNING / EXECUTION / VERIFICATION) set on each `task_boundary` call, with explicit backtracking rules ("Return to PLANNING if you discover unexpected complexity"). Three persistent artifacts: task.md (a living checklist using `[ ]` / `[/]` in-progress / `[x]`), implementation_plan.md, walkthrough.md. The plan format is unusually mechanical: Proposed Changes groups files by component ordered dependencies-first, and each file is its own heading tagged with the operation and hyperlinked — `#### [MODIFY] [file basename](file:///absolute/path)`, `#### [NEW] ...`, `#### [DELETE] ...`. A Verification Plan section is split into "Automated Tests — Exact commands you'll run" and "Manual Verification". A "## User Review Required" section is required only when breaking changes or significant design decisions exist, and "If there are no such items, omit this section entirely." Review is requested via `notify_user` with `PathsToReview`, `ConfidenceScore`, `ConfidenceJustification`, and `BlockedOnUser`.
  - *Reported results:* None reported. Leaked prompt.
  - *Source:* https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools/blob/main/Google/Antigravity/planning-mode.txt
- **No planner agent at all — in-context todo list with a size floor (Cursor)** — The deliberate counter-position, worth knowing because it comes from the highest-volume coding agent in production. There is no plan file, no architect mode, no delegation. Instead a `todo_spec`: "Create atomic todo items (≤14 words, verb-led, clear outcome)"; "Todo items should be high-level, meaningful, nontrivial tasks that would take a user at least 5 minutes to perform"; "Todo items should NOT include operational actions done in service of higher-level tasks"; "Prefer fewer, larger todo items." And explicitly: "If the user asks you to implement, do not output a separate text-based High-Level Plan. Just build and display the todo list." A hard gate ties the list to edits: "Before starting any new file or code edit, reconcile the TODO list via todo_write (merge=true): mark newly completed tasks as completed and set the next task to in_progress."
  - *Reported results:* None reported. But its existence is evidence: a company with enormous usage telemetry chose no planner/implementer split for its default agent. Whatever the split buys, Cursor did not judge it worth the latency at their default.
  - *Source:* https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools/blob/main/Cursor%20Prompts/Agent%20Prompt%202025-09-03.txt
- **Pipeline with a filesystem state machine (wshobson ship-mate)** — orchestrate (Sonnet, product spec) → architect (inherit, technical plan) → implement (Sonnet, code) → review, coordinated by `.claude/pipeline/state.json` where each stage sets `checkpoints.<stage>` to `completed` or `awaiting_approval` and sets `stage` for the next actor. Each stage names its exact input files at the top of its prompt ("Read `AGENTS.md` and `.claude/pipeline/architect-plan.md` before writing any code"). The architect emits a fixed-schema plan with Files to Create and Files to Modify as two-column markdown tables, plus a Test Plan, a Security Checklist, and a Definition of Done. The architect has explicit escalation triggers (external API contract changes, destructive schema changes, auth/security model changes, complexity exceeding story scope, insufficient information) at which it must "write a clear question to the human and halt. Do not guess." The implementer has a matching deviation protocol: rather than silently skipping an impossible step it must emit a structured "⚠️ Plan deviation required" block naming the step number, the issue, and the proposed adjustment.
  - *Reported results:* None reported. Ships inside a repo with genuine structural CI, but no outcome measurement.
  - *Source:* https://github.com/wshobson/agents/blob/main/plugins/ship-mate/agents/architect.md

---

## Sweep 3

**Angle.** Academic literature (arXiv / ACL / ICLR / NeurIPS / FSE / EMNLP) on planner-orchestrator design for multi-agent coding systems, with emphasis on measured ablations and negative results.

### Sources (25)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | Cemri et al., "Why Do Multi-Agent LLM Systems Fail?" — MAST taxonomy of 14 failure modes from 1600+ annotated traces across 7 MAS frameworks (ChatDev, AG2/AutoGen, HyperAgent, AppWorld, etc.), inter-annotator kappa 0.88. Includes intervention experiments on ChatDev. | https://arxiv.org/abs/2503.13657 |
| `peer-reviewed-or-benchmarked` | Xia et al., "Agentless: Demystifying LLM-based Software Engineering Agents" — deliberately non-agentic localize→repair→validate pipeline, with a full ablation of every stage on SWE-bench Lite. | https://arxiv.org/abs/2407.01489 |
| `peer-reviewed-or-benchmarked` | "Evaluating Plan Compliance in Autonomous Programming Agents" (2026 preprint) — 16,991 agent trajectories over 500 SWE-bench Verified instances + SWE-bench Pro, 4 models, 8 plan variants. Measures whether agents actually follow the localize→reproduce→patch→validate plan in their system prompt, and whether compliance correlates with resolution. | https://arxiv.org/html/2604.12147v2 |
| `peer-reviewed-or-benchmarked` | "Handoff Debt: The Rediscovery Cost When Coding Agents Take Over Interrupted Tasks" (2026 preprint) — 181 handoff-point tasks derived from 75 SWE-bench Verified tasks, 2,172 takeover runs, comparing 4 handoff context formats (repo-only, raw trace, summary notes, structured notes). | https://arxiv.org/html/2606.02875 |
| `peer-reviewed-or-benchmarked` | "Single-Agent LLMs Outperform Multi-Agent Systems on Multi-Hop Reasoning Under Equal Thinking Token Budgets" (2026 preprint) — 6 topologies incl. a Planner→Workers sequential MAS, compared to single-agent at matched token budgets. NOT a coding benchmark (FRAMES, MuSiQue). | https://arxiv.org/html/2604.02460v1 |
| `peer-reviewed-or-benchmarked` | MetaGPT (ICLR 2024) — SOP-driven role pipeline (Product Manager / Architect / Project Manager / Engineer / QA) with structured document handoff and a publish-subscribe message pool. Contains a role-addition ablation on SoftwareDev. | https://arxiv.org/html/2308.00352v6 |
| `peer-reviewed-or-benchmarked` | CodeR: Issue Resolving with Multi-Agent and Task Graphs — a Manager agent that SELECTS a pre-written task graph rather than inventing a plan. 28.33% on SWE-bench Lite (2024). | https://arxiv.org/html/2406.01304v3 |
| `peer-reviewed-or-benchmarked` | MapCoder (ACL 2024) — 4 agents (Retrieval, Planning, Coding, Debugging); planner emits k plans with confidence scores, traversed highest-first. Full agent-removal ablation and k/t sweep. | https://ar5iv.labs.arxiv.org/html/2405.11403 |
| `peer-reviewed-or-benchmarked` | CodeSIM (2025) — planner verifies its own plan by mentally simulating it on sample inputs BEFORE any code is written. Also reports a failed reproduction of AgentCoder. | https://arxiv.org/pdf/2502.05664 |
| `peer-reviewed-or-benchmarked` | SWE-agent (NeurIPS 2024) — agent-computer interface design; ablations show interface/guardrail design, not planning, is where the points come from. | https://arxiv.org/abs/2405.15793 |
| `peer-reviewed-or-benchmarked` | Valmeekam, Stechly, Kambhampati — "LLMs Still Can't Plan; Can LRMs?" o1 on PlanBench: 97.8% standard Blocksworld, 52.8% Mystery Blocksworld, collapse beyond ~20-step plans, cannot reliably detect unsolvable instances. | https://arxiv.org/abs/2409.13373 |
| `peer-reviewed-or-benchmarked` | Kambhampati et al., ICML 2024 position paper: "LLMs Can't Plan, But Can Help Planning in LLM-Modulo Frameworks" — LLMs as candidate-plan generators inside a generate-test loop with EXTERNAL sound verifiers. | https://proceedings.mlr.press/v235/kambhampati24a.html |
| `peer-reviewed-or-benchmarked` | Huang et al., ICLR 2024, "Large Language Models Cannot Self-Correct Reasoning Yet" — intrinsic self-correction without external feedback does not improve and often degrades performance. | https://arxiv.org/pdf/2310.01798 |
| `peer-reviewed-or-benchmarked` | Wang et al., "Planning In Natural Language Improves LLM Search For Code Generation" (PlanSearch) — searching over natural-language plans instead of code. Claude 3.5 Sonnet pass@200 77.0% on LiveCodeBench vs 60.6% for repeated sampling, pass@1 41.4%. | https://arxiv.org/abs/2409.03733 |
| `peer-reviewed-or-benchmarked` | CodePlan (FSE 2024, Microsoft) — repo-level coding as a symbolic planning problem: dependency + change-impact analysis synthesizes a chain-of-edits; each step is an LLM call at a specific code location. | https://dl.acm.org/doi/pdf/10.1145/3643757 |
| `peer-reviewed-or-benchmarked` | "Select-Then-Decompose" (EMNLP 2025 main) — empirical analysis showing decomposition is not universally better than direct/CoT, plus a router that decomposes only when the task warrants it. | https://aclanthology.org/2025.emnlp-main.278.pdf |
| `peer-reviewed-or-benchmarked` | Kimi-Dev: "Agentless Training as Skill Prior for SWE-Agents" — 60.4% SWE-bench Verified with the Agentless workflow (best among workflow approaches); 48.6% pass@1 when the same model drives a free-form SWE-Agent. | https://arxiv.org/abs/2509.23045 |
| `peer-reviewed-or-benchmarked` | Dong et al., "Self-collaboration Code Generation via ChatGPT" (TOSEM 2024) — analyst/coder/tester role instructions; +29.9%–47.1% relative pass@1 over base ChatGPT, 74.4% HumanEval. | https://arxiv.org/pdf/2304.07590 |
| `peer-reviewed-or-benchmarked` | Rasheed et al., "LLM-Based Multi-Agent Systems for Code Generation: A Multi-Vocal Literature Review" (2026) — 114 studies incl. grey literature; six challenge categories (correctness/reliability, security, compute cost, context & memory limits, benchmarks, verification, prompt engineering). | https://arxiv.org/html/2604.16321v1 |
| `peer-reviewed-or-benchmarked` | Holistic Agent Leaderboard (HAL) — 21,730 agent rollouts, 9 models × 9 benchmarks, ~$40k, standardized harness. Finds higher reasoning effort REDUCES accuracy in a majority of runs. | https://arxiv.org/pdf/2510.11977 |
| `peer-reviewed-or-benchmarked` | ReWOO: Decoupling Reasoning from Observations — Planner emits the full interleaved plan with variable references up front; Workers execute; Solver integrates. ~5x token reduction vs ReAct. | https://arxiv.org/abs/2305.18323 |
| `peer-reviewed-or-benchmarked` | Agent Planning Benchmark (2026 preprint) — separates holistic planning, step-wise planning, robustness to extraneous tools, recovery from broken tools, and calibrated refusal on unsolvable tasks. 12 models. | https://arxiv.org/html/2606.04874 |
| `practitioner-battle-tested` | mini-SWE-agent — ~100 lines of Python, bash-only, no planner, no tool schema, no verification scaffold; reported >74% on SWE-bench Verified. Widely used as a reference baseline. | https://github.com/swe-agent/mini-swe-agent |
| `popular-but-unvalidated` | AgentCoder — programmer / test-designer / test-executor. Claims 96.3% HumanEval pass@1 with GPT-4. Notable primarily because a later paper failed to reproduce it. | https://arxiv.org/abs/2312.13010 |
| `unverified` | "Inside the Scaffold: A Source-Code Taxonomy of Coding Agent Architectures" (2026 preprint) — source-level analysis of ~16 coding agents (Aider, SWE-agent, OpenHands, AutoCodeRover, Agentless...) across planning/context/action/verification dimensions. | https://arxiv.org/pdf/2604.03515 |

### Verbatim prompt excerpts (12)

**CodeR: Issue Resolving with Multi-Agent and Task Graphs (arXiv 2406.01304)**

```
planning at the beginning of the pipeline is better than deciding the next steps on-the-go
```

> The clearest academic statement of the plan-first-then-execute doctrine for repo-scale coding, and the authors' reason is prompt-relevant: on-the-go decisions rely on instruction-following and long-horizon memory, both of which LLMs are bad at. Backed by 28.33% SWE-bench Lite (+10.33 pts over SWE-agent) and a 22%→10% drop when task graphs are removed.

**Evaluating Plan Compliance in Autonomous Programming Agents (arXiv 2604.12147)**

```
the plan is only advisory: it is included in the system prompt, but the scaffold's execution engine provides no mechanism to enforce it
```

> Directly contradicts the implicit assumption behind most planner prompts. If you want a phase to happen, either the harness must gate on it or the plan must be reinjected periodically — measured: reminders every 5 steps improved success across all four models tested.

**Evaluating Plan Compliance in Autonomous Programming Agents (arXiv 2604.12147)**

```
The negative impact of a bad, incomplete plan is greater on trajectories than the impact of no plan at all.
```

> This is the argument for a minimal, high-confidence plan over an ambitious one. Concretely: if the planner is unsure whether a reproduction step is needed, omitting the whole plan is safer than shipping a plan missing that step.

**Evaluating Plan Compliance in Autonomous Programming Agents (arXiv 2604.12147)**

```
Augmenting plans with task-relevant phases ... negatively affects agents' performance when they are not aligned with the model's internal strategy.
```

> Kills the 'more thorough plan = better' instinct with a measurement. Adding an early regression-test phase — an obviously sensible-looking addition — degraded DeepSeek-V3.

**Agentless: Demystifying LLM-based Software Engineering Agents (arXiv 2407.01489)**

```
Lack of control in decision planning ... agents become confused navigating large action spaces, potentially requiring 30-40 turns per issue; Limited ability to self-reflect ... agents amplify errors from irrelevant or misleading feedback across subsequent decisions
```

> The explicit indictment of agentic planning from the paper that then beat those agents at 1/3 to 1/5 the cost. 'Amplify errors from misleading feedback' is the mechanism to design against: constrain what feedback reaches the implementer.

**CodeSIM (arXiv 2502.05664)**

```
Plan Verification = Simulate(Plan, Sample Input) =? Expected Output
```

> A plan self-check that is actually checkable, because it terminates in a comparison against a known expected output rather than a model opinion. Translates to a prompt line: 'before handing off, trace your plan on one concrete input from the issue and state the expected result; if it does not match, revise the plan.'

**MetaGPT (ICLR 2024, arXiv 2308.00352)**

```
unconstrained natural language communication is like the 'telephone game' where information may be quite distorted [after sequential passes]
```

> Motivates fixed-field handoff artifacts. MetaGPT's Architect emits file lists, data structures, interface definitions, call flow, and per-file logic analysis — a concrete field list you can copy into a planner's output schema.

**Handoff Debt (arXiv 2606.02875) — structured notes format**

```
deterministic fields (changed files, validation commands) plus model-generated fields (understanding, evidence, uncertainty, next steps)
```

> An empirically-tested six-field handoff schema. The 'uncertainty' and 'evidence' fields are unusual and worth copying; the deterministic/model-generated split is the part that makes the record auditable.

**Why Do Multi-Agent LLM Systems Fail? (arXiv 2503.13657) — MAST failure modes with measured frequency**

```
FC1 System design 44.2% [disobey task spec 11.8%, disobey role spec 1.5%, step repetition 15.7%, loss of conversation history 2.8%, unaware of termination conditions 12.4%]; FC2 Inter-agent misalignment 32.3% [conversation reset 2.2%, fail to ask for clarification 6.8%, task derailment 7.4%, information withholding 0.8%, ignored other agent's input 1.9%, reasoning-action mismatch 13.2%]; FC3 Task verification 23.5% [premature termination 6.2%, no/incomplete verification 8.2%, incorrect verification 9.1%]
```

> This is the highest-value single artifact for authoring these prompts: it is a frequency-ranked list of exactly what goes wrong. The top five by frequency — step repetition, reasoning-action mismatch, unaware of termination conditions, disobey task specification, incorrect verification — should each map to one explicit line in the planner or implementer prompt.

**Why Do Multi-Agent LLM Systems Fail? (arXiv 2503.13657) — ChatDev intervention experiment**

```
ProgramDev: baseline 25.0% → improved prompt 34.4% → new topology (cyclic workflow with CTO verification gate) 40.6%. HumanEval: 89.6% → 90.3% → 91.5%.
```

> Quantifies the ceiling of prompt engineering versus structural change on the same system: +9.4 pts from prompts, +15.6 pts from topology. Also shows the effect nearly vanishes on a saturated benchmark (HumanEval +1.9 pts total) — a warning about which benchmark you validate a prompt change on.

**Kimi-Dev (arXiv 2509.23045)**

```
60.4% on SWE-bench Verified [with the fixed Agentless workflow] ... 48.6% pass@1 [driving a free-form SWE-Agent]
```

> Same model, two control-flow regimes, 11.8 pt gap in favor of the fixed workflow. This is the tightest available answer to 'is letting the model plan its own steps worth it?' and the answer at the time was no.

**mini-SWE-agent (SWE-agent/mini-SWE-agent)**

```
The 100 line AI agent that solves GitHub issues ... no huge configs, no giant monorepo—but scores >74% on SWE-bench verified! [The agent] does not have any tools other than bash
```

> The strongest single piece of evidence against elaborate planner/implementer machinery. Any planner design should be able to articulate what it adds over a bash loop with a good prompt — and be measured against it.

### Approaches (12)

- **No planner at all — fixed localize→repair→validate pipeline (Agentless)** — There is no planning agent and no LLM-chosen control flow. A hard-coded three-phase pipeline: (1) hierarchical localization — repo tree → suspicious files → classes/functions → exact edit locations; (2) repair — sample N candidate patches in a simple search/replace diff format at those locations; (3) validation — run regression tests plus LLM-generated reproduction tests, then rank/majority-vote patches. The 'plan' is the pipeline itself, written by the system author, not by a model.
  - *Reported results:* SWE-bench Lite 32.00% (96/300) at $0.70/issue vs SWE-agent $1.62–2.53 and CodeR $3.34 — highest performance among open-source approaches at the time. Per-stage ablation: hierarchical localization gets ground-truth file in 81.67% (prompting 78.67%, embedding 70.33%) vs 47.00% for direct file→edit-location localization. Validation ablation: majority voting alone 25.67% → +regression tests 27.00% → +reproduction tests 32.00%. Repair sampling: 4 location sets × 10 patches = 32.00% vs greedy single location 29.33%; upper bound with perfect ranking 42.0%.
  - *Source:* https://arxiv.org/abs/2407.01489
- **Manager agent SELECTS a pre-written task graph (CodeR)** — The orchestrator does not author a plan. It picks one of four hand-written JSON task graphs (Plan A: Reproducer→Fault Localizer→Editor→Verifier; Plan B: direct; Plan C: with feedback loops; Plan D: test-driven) based on the issue text. Each graph node names the agent, its subtask, and downstream edges conditioned on success/failure. The Manager's only other job is to read the execution summary and decide submit / replan / exit.
  - *Reported results:* 28.33% SWE-bench Lite (single submission, 2024). Ablation on 50 issues: full CodeR 22%, without multi-agent+task graphs 10%, without fault localization 14%. Hybrid SBFL+BM25 localization improved top-5 precision by >10% over either alone.
  - *Source:* https://arxiv.org/html/2406.01304v3
- **Plan-as-system-prompt (SWE-agent, OpenHands, mini-SWE-agent)** — A single agent, no planner subagent. The workflow (navigate → reproduce → patch → validate) is written as prose instructions in the system prompt; the agent runs a flat ReAct/bash loop against a purpose-built agent-computer interface (paged file viewer, structured edit command with a lint guardrail, concise per-command feedback). Context is managed by condensers/summarization, not by an orchestrator holding state.
  - *Reported results:* SWE-agent (NeurIPS 2024): 12.47% of full SWE-bench with GPT-4 Turbo vs 3.8% prior best; ACL ablation on 300 instances shows +10.7 pts over a plain Linux-shell baseline; removing the edit lint guardrail costs 3.0 pts (15.0% without). mini-SWE-agent: ~100 lines, bash only, no planner/verification scaffold, reported >74% SWE-bench Verified. OpenHands CodeAct v2.1 53.0% Verified (Apr 2025), v3 on Claude Opus 4.6 ~68.4%. Independent 2026 study finds agents follow this prompt-level plan only partially — it is advisory, not enforced.
  - *Source:* https://arxiv.org/abs/2405.15793
- **SOP-encoded role pipeline with structured document handoff (MetaGPT)** — Roles (Product Manager → Architect → Project Manager → Engineer → QA) are wired into a fixed SOP. The Architect's output is not prose: it is a file list, data structures and interface definitions (class hierarchies, method signatures), a call-flow/sequence diagram, and a 'logic analysis' mapping each file to its responsibility. Agents publish these structured documents into a global message pool and SUBSCRIBE only to the document types their role needs, rather than passing conversation turns.
  - *Reported results:* 85.9% HumanEval / 87.7% MBPP pass@1. Role-addition ablation on SoftwareDev (executability 1–4 scale): Engineer only 1.0 → +Product Manager 2.0 → +Architect 2.5 → all four roles 4.0, with human revisions falling 10 → 2.5. Executable-feedback ablation: +4.2% HumanEval, +5.4% MBPP; revisions 2.25 → 0.83. Caveat: HumanEval/MBPP are saturated and contamination-prone; SoftwareDev executability is a subjective 1–4 human score on 11 tasks.
  - *Source:* https://arxiv.org/html/2308.00352v6
- **Multi-plan generation with confidence-ranked traversal (MapCoder)** — The Planning Agent emits k distinct plans, each with a self-assessed confidence score. Plans are sorted; the highest-confidence plan goes to the Coding Agent; if the code fails sample I/O the Debugging Agent gets up to t attempts; if that fails, control returns to the planner and the NEXT-highest-confidence plan is tried. The planner never sees the code — it only supplies the next candidate strategy.
  - *Reported results:* HumanEval 93.9%, MBPP 83.1%, APPS 22.0%, CodeContests 28.5%, xCodeEval 45.3% (pass@1). Agent-removal ablation on HumanEval/ChatGPT: full 93.9%, without Debugging 76.4%, without Planning 77.2%, without Retrieval 86.6% (planner is the 2nd most important agent; ~16.7% average drop when removed). k/t sweep: (1,1) 84.8% → (3,3) 92.1% → (5,5) 93.9% → (7,7) 94.2%, i.e. sharply diminishing returns after k=5.
  - *Source:* https://ar5iv.labs.arxiv.org/html/2405.11403
- **Plan verification by simulation before any code is written (CodeSIM)** — The planner produces a plan, then simulates that plan step-by-step on a sample input, tracking intermediate state, and compares the simulated output to the known expected output. Formally: Simulate(Plan, SampleInput) =? ExpectedOutput. If they diverge, the plan is revised BEFORE the coding agent is invoked. Error detection is moved from the debug phase to the plan phase.
  - *Reported results:* 95.1% HumanEval, 90.7% MBPP (GPT-4o); reported ~7.1% higher accuracy than MapCoder while using ~4.13K fewer tokens. Ablations confirm both plan-verification-by-simulation and simulation-driven debugging are individually load-bearing (exact per-ablation deltas were not extractable from the copies I fetched). Also reports a failed independent reproduction of AgentCoder — 56.7% (ChatGPT) and 17.7% (GPT-4) on HumanEval, ~$500 and >10M tokens spent, against AgentCoder's claimed 79.9%/96.3%.
  - *Source:* https://arxiv.org/pdf/2502.05664
- **Symbolic planner over a dependency graph, LLM only as an edit executor (CodePlan)** — Repo-level change is treated as a formal planning problem. Incremental dependency analysis plus change-may-impact analysis synthesize a chain-of-edits; each plan step is a concrete (code location, context, instruction) triple handed to the LLM. After each edit, the impact analysis re-runs and the plan is ADAPTED — the plan is a live artifact recomputed from the code, not a static list written once at the start.
  - *Reported results:* On package migration (C#) and temporal code edits (Python) spanning 2–97 interdependent files per repo: CodePlan gets 5/7 repositories to pass validity checks (builds cleanly, edits correct); baselines with the same contextual information but no planning pass 0/7. This is one of the cleanest 'planning helps' results in the literature because the baseline is context-matched.
  - *Source:* https://dl.acm.org/doi/pdf/10.1145/3643757
- **Planner–Worker–Solver decoupling with the whole plan emitted up front (ReWOO)** — The Planner writes the complete blueprint of steps and tool calls in one shot, using variable references (#E1, #E2) so later steps can consume earlier evidence without the planner ever seeing the observations. Workers execute independently (parallelizable). A Solver integrates plan + evidence into the answer. Total LLM calls: 2, regardless of tool count — versus one per step in ReAct.
  - *Reported results:* ~5x token reduction versus ReAct with higher accuracy on multi-step reasoning benchmarks. Note: 2023, evaluated on QA/tool-use, NOT on repo-scale coding; the cost-saving argument is well-supported, the coding transfer is not.
  - *Source:* https://arxiv.org/abs/2305.18323
- **LLM-Modulo: LLM proposes plans, external sound verifiers accept/reject** — The LLM is a candidate-plan generator and critique-translator only. Verification is delegated to external, sound checkers (model-based validators, simulators, test runners). A generate–test loop iterates with verifier feedback until the plan passes. The LLM is never trusted to verify its own plan.
  - *Reported results:* Argument-level, backed by PlanBench: o1 scores 97.8% on standard Blocksworld but 52.8% on the obfuscated Mystery Blocksworld, degrades sharply beyond ~20-step plans, and cannot reliably recognize unsolvable instances. Complementary ICLR 2024 evidence (Huang et al.): intrinsic self-correction without external feedback does not improve and often degrades results. Together: self-verified plans are unreliable; verifier-in-the-loop plans are the supported design.
  - *Source:* https://proceedings.mlr.press/v235/kambhampati24a.html
- **Search over natural-language plans rather than over code (PlanSearch)** — Generate a diverse set of observations about the problem, combine them into multiple distinct natural-language plans, then translate each plan into code. The planner's job is explicitly to produce DIVERSITY, not the single best plan — the paper shows measured idea-diversity predicts the gain from search.
  - *Reported results:* Claude 3.5 Sonnet on LiveCodeBench (contamination-free): pass@200 77.0% with PlanSearch vs 60.6% with plain repeated sampling and pass@1 41.4% without search. Gains across all models/benchmarks are predictable as a direct function of generated-idea diversity. Relevant caveat: this is a pass@k / many-sample regime, not a single-shot production agent regime.
  - *Source:* https://arxiv.org/abs/2409.03733
- **Structured handoff record as the planner→implementer contract (Handoff Debt)** — When one agent hands work to another, it emits a fixed-field record: deterministic fields (changed files, validation commands) plus model-generated fields (current understanding, evidence, uncertainty, next steps). Compared head-to-head against repo-only, raw full trace, and free-form summary notes.
  - *Reported results:* On 181 handoff points from 75 SWE-bench Verified tasks (2,172 runs, 3 successor models): raw trace cut median successor events 57–59% and improved resolve rate 6–15 pts; summary notes 20–46% event reduction; structured notes 20–44% event reduction but only 1–10 pts resolve gain, often not statistically significant. Prompt tokens fell 42–63% for all context-bearing formats. The most valuable content was VALIDATION EVIDENCE — what was tested, what failed, and how the predecessor responded (+12–19 pts at post-failed-test handoff points). Honest read: raw traces beat curated notes on outcome, which is uncomfortable for the 'orchestrator holds only summaries' doctrine.
  - *Source:* https://arxiv.org/html/2606.02875
- **Select-then-decompose: route to decomposition only when the task warrants it** — Before decomposing, a selector evaluates task characteristics and chooses among direct answering, CoT, and full decomposition. Decomposition is applied conditionally rather than as the default control flow.
  - *Reported results:* Central finding: 'decomposition isn't universally superior' — there are task classes where decomposition improves accuracy at higher cost and task classes where it degrades accuracy AND costs more. EMNLP 2025 main track, but evaluated on general reasoning rather than coding, so transfer to repo-scale coding is an inference, not a measurement.
  - *Source:* https://aclanthology.org/2025.emnlp-main.278.pdf

---

## Sweep 4

**Angle.** Practitioner forums (HN threads + comments, GitHub issues on anthropics/claude-code, measured third-party benchmarks, dev blogs). Reddit was inaccessible — reddit.com is blocked to this crawler — so Reddit content only appears where HN reposted it. Everything below is anecdote unless explicitly marked as measured. The single strongest finding: the loudest, most repeated complaint is NOT "plans are bad" — it is that the implementer subagent starts blind (no CLAUDE.md, no rules, no hooks, no project memory), and every workaround people independently converged on is a way to force context INTO the subagent prompt itself.

### Sources (23)

| Credibility | What it is | URL |
|---|---|---|
| `peer-reviewed-or-benchmarked` | 'The Subagent Tax' — third-party measured benchmark of Claude Code fan-outs via a logging proxy with SHA-256 hash-chained audit trail, 105 verified entries. Identical tasks run sequential vs 2 subagents vs 5 subagents, on two model families. Vendor blog (they sell the proxy), small n, but the methodology and raw numbers are disclosed. | https://systima.ai/blog/subagent-tax |
| `peer-reviewed-or-benchmarked` | Measured token floor of a subagent spawn: 27,403 tokens default headless, ~22k of which is built-in tool schemas; drops to 1,965 tokens with `tools: []` frontmatter. Raw measurement JSONs linked. | https://github.com/anthropics/claude-code/issues/76045 |
| `primary-official` | Anthropic's own multi-agent research write-up: 90.2% improvement over single-agent Opus 4 on an internal research eval, ~15x tokens vs chat, token usage explains 80% of performance variance. NOTE: June 2025, one year old, and Anthropic explicitly scopes the result to breadth-first research and says multi-agent is LESS effective for tightly interdependent tasks such as coding. | https://www.anthropic.com/engineering/built-multi-agent-research-system |
| `primary-official` | Anthropic's Opus 5 prompting guidance, which explicitly tells authors to REMOVE 'use a subagent to verify' style instructions because they cause over-verification and wasted tokens. Directly contradicts a very common line in community agent prompts. | https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 |
| `practitioner-battle-tested` | HN thread (288 pts, 128 comments, Sep 2025) on 'How to use Claude Code subagents to parallelize development'. The comments are far more informative than the article — heavy dissent about handoff quality, token burn, and whether persona agents do anything. | https://news.ycombinator.com/item?id=45181577 |
| `practitioner-battle-tested` | Feature request: opt-in context inheritance for Agent-spawned subagents. Contains forensic data from a 9-day incident: 296 subagent sessions, 4 interactive sessions, zero project memories persisted, with an enumerated list of convention violations caused by blind subagents. | https://github.com/anthropics/claude-code/issues/69283 |
| `practitioner-battle-tested` | 'Subagents should inherit parent agent context to avoid redundant codebase scanning' (Dec 2025, 10 comments). Contains the most-cited practitioner report in this whole research: a user with 11 custom production agents documenting four different attempts to make subagents follow instructions, all failing, and the one thing that worked. | https://github.com/anthropics/claude-code/issues/12790 |
| `practitioner-battle-tested` | 'Subagent terminated mid-task (budget/context) is reported to parent as completed — silent truncation.' Reproducible: subagent loop dies around ~18-20 tool uses before writing its deliverable; parent gets a normal 'completed' result and no file. | https://github.com/anthropics/claude-code/issues/73372 |
| `practitioner-battle-tested` | 'Agent team lost when lead's context gets compacted during long session' (18 comments). The orchestrator forgets it has a team after compaction; one commenter reports the lead also lost its 'project manager only' role constraint after 4 compactions and started implementing directly. | https://github.com/anthropics/claude-code/issues/23620 |
| `practitioner-battle-tested` | Agent Teams duplicate-spawn bug: 30 Agent tool calls → 107 subagent transcripts on disk (3.5x); one report of 592 agents from 17 calls. Compaction-induced re-spawn is one of three compounding mechanisms. Duplicates opened a duplicate PR. | https://github.com/anthropics/claude-code/issues/55586 |
| `practitioner-battle-tested` | Opus orchestrator + Haiku-pinned subagents still drains quota at Opus rate: 35% of a 5-hour window consumed in ~1 hour of pure-orchestration work. User later reports /usage showed the `model: haiku` pin was silently ignored. | https://github.com/anthropics/claude-code/issues/52502 |
| `practitioner-battle-tested` | Workflow subagents retry from blank context after a session-limit error, redoing completed work. Journal recorded ~857,688 subagent tokens initial run + ~232,590 resumed. Claude selected ~13 Fable-5 agents for a contained CSS/TSX task with no cost preview. | https://github.com/anthropics/claude-code/issues/80253 |
| `practitioner-battle-tested` | 'Plan mode resurfaces old plans after session compaction' — 7+ independent confirmations that a stale plan .md file on disk gets re-presented for a new, unrelated task, and the loop only breaks when the user forces deletion of the plan file. | https://github.com/anthropics/claude-code/issues/12505 |
| `practitioner-battle-tested` | HN thread (123 pts, 89 comments, Sep 2025) on Cognition's 'Don't Build Multi-Agents'. Comments include the framing that a subagent's value is compression, plus reports that Claude Code doesn't actually parallelize. | https://news.ycombinator.com/item?id=45096962 |
| `practitioner-battle-tested` | HN thread 'Agent orchestration for the timid' (128 pts, 32 comments, Jan 2026). Split verdict: deterministic state machines and 2-4 concurrent changes work; more agents means more drift and merge conflicts; nobody can keep track. | https://news.ycombinator.com/item?id=46746681 |
| `practitioner-battle-tested` | dev.to post by an author running 5 specialist agents + Opus orchestrator with 1,400+ tests across 22 versions. Central claim: 'Custom subagents do not inherit your project configuration' cost weeks of debugging; fix was to move critical restrictions from prompts into a permission engine. | https://dev.to/blacksun/i-built-a-production-agent-orchestrator-then-claude-codes-source-leaked-and-i-saw-the-same-5e85 |
| `practitioner-battle-tested` | Test of 3-level nested subagents (orchestrator → worker → sub-worker) on a real GitHub issue: 148,000 tokens across six runs, 21 minutes. Author found no depth guardrail — recursed ~30 levels before cancelling. | https://newsletter.aiengineer.co/p/i-tested-nested-subagents-in-claude |
| `practitioner-battle-tested` | TaskOutput on a still-running local_agent task dumps the raw subagent JSONL transcript (tool_use/tool_result blobs, base64 thinking signatures) into the caller's context instead of a status object. Corroborated on a second version by a second reporter. | https://github.com/anthropics/claude-code/issues/76335 |
| `practitioner-battle-tested` | CLAUDE.md rules not propagated to subagents AND weakened after compaction. Long thread where three practitioners converge on the same diagnosis and one demonstrates a ~40-line SubagentStart + PreCompact injection fix; another contributes the DECISIONS.md append-only ledger pattern. | https://github.com/anthropics/claude-code/issues/59309 |
| `popular-but-unvalidated` | Aggregator post citing an MIT relay-degradation study (90.7% → 41.2% → 22.5% accuracy across 1/2/5 relay stages), a Google 180-config scaling study (17.2x vs 4.4x error amplification), and a prose-vs-structured-relay delta (8.5 vs 2.8 points lost per stage). I did NOT independently verify any of these citations. | https://medium.com/@Micheal-Lanham/multi-agent-in-production-in-2026-what-actually-survived-f86de8bb1cd1 |
| `anecdote` | HN thread (Jul 2026) on the report that Claude Code hardcodes an instruction telling Opus 5 not to use subagents. Small (13 comments) but contains the sharpest recent dissent, and is notable as a signal about vendor direction. | https://news.ycombinator.com/item?id=49056022 |
| `anecdote` | Honest negative-ish report (Jun 2026): seven planning subagents produced internally-consistent but mutually contradictory specs (backend spec'd confidence scores, product spec'd detect/post/done); neither could see the conflict. Author concludes six of seven roles were commodity; only the read-only adversarial reviewer retained value. | https://alirezarezvani.substack.com/p/my-seven-claude-code-subagents-did |
| `anecdote` | Ask HN: Are you using Spec Driven Development? (Jun 2026). Small but useful: practitioners report using a strong model to write specs that cheaper models implement, with 80%+ coverage gates baked into the spec. | https://news.ycombinator.com/item?id=48510002 |

### Verbatim prompt excerpts (10)

**GitHub user ThatDragonOverThere, anthropics/claude-code issue #12790 — reporting what did NOT work across 11 production agents**

```
[in all 11 agent MDs, prominent, at the top] 'MANDATORY: Sub-Agent Workflow' ... [as Rule #1 in CLAUDE.md] 'USE SUB-AGENTS FOR ALL WORK. Main context is for COORDINATION ONLY.'
```

> This is the exact shape of prompt line most orchestrator templates ship with, and it is documented as ineffective. The reporter's finding: 'Agent definition MDs and CLAUDE.md are effectively decorative for sub-agent behavior.' If your planner agent's system prompt contains a line like this, it must live in the Agent tool `prompt` parameter instead.

**Anthropic, Opus 5 prompting guidance (platform.claude.com), quoted by HN user ValentineC**

```
If your prompt contains explicit verification instructions ("include a final verification step for any non-trivial task," "use a subagent to verify"), remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality.
```

> Vendor guidance that directly contradicts a near-universal community pattern. Concrete effect on an agent definition: delete the 'verify with a subagent' clause, keep the command-level gate (tests/lint must pass) instead.

**HN user ArkNill, anthropics/claude-code issue #42910**

```
use a subagent to run the linter and report only the errors
```

> The correct shape of a delegation instruction, stated by a practitioner as the only lever available when the model won't delegate on its own. Note the two halves: name the exact command, and bound the return payload. This is the template for every implementer dispatch line in an orchestrator prompt.

**GitHub user kcarriedo, anthropics/claude-code issue #59309**

```
write hard constraints to a `DECISIONS.md` file the agent re-reads on every major step, and reference it explicitly in CLAUDE.md as the source of truth for "rules that override anything else." Treats operator rulings as code rather than conversation. CLAUDE.md is the wrong file for this because it grows unboundedly; a dedicated append-only ledger does better.
```

> Directly translatable to two prompt lines: (1) in the planner — 'append every ratified decision to DECISIONS.md'; (2) in the implementer — 'read DECISIONS.md before starting and before each file edit'. Motivated by the observed failure that compaction demotes rules from constraints to history.

**HN user gck1, on why he abandoned built-in plan mode**

```
Built in one creates md files outside the project, gives the files random names and its hard to reference in the future. ... Every time /implement command is initiated, it has to create markdown file inside my own project, and then each subagent is also instructed to update the file when it finished working. This way, orchestrator can spot that agent misbehaved, and reviewer agent can see what developer agent tried to do and why it was wrong.
```

> Two concrete prompt requirements: the plan file path must be deterministic and inside the repo, and the implementer's contract must include writing its outcome back into the plan file. That write-back is what makes misbehaviour detectable without the orchestrator holding raw output.

**HN user lucraft, on the zachwills subagents thread**

```
Don't make subagents for the different roles, make them to manage context for token heavy tasks... The ideal sub agent is one that can take a simple question, use up massive amounts of tokens answering it, and then return a simple answer.
```

> A usable admission test for the planner's decomposition step: 'only dispatch a subagent when the input is small, the work is large, and the required output is small.' Screens out persona agents and screens out steps that need the parent's accumulated nuance.

**anthropics/claude-code issue #73372 (reporter's own recommendation)**

```
orchestrators must implement out-of-band truncation detection (report-footer contracts, artifact existence checks) to avoid trusting false completions in multi-agent workflows.
```

> Two implementable mechanisms. Report-footer contract = require the implementer to end with a fixed sentinel line; its absence means truncation. Artifact existence check = the orchestrator runs `test -f <path>` / `git diff --stat` after every dispatch rather than believing the status.

**HN user a_t48, quoting a Fable-generated session-closure format he was told to adopt (he pushed back on it)**

```
Decision: Use CacheMountStore with registry/local/GHA backends. Why: GHA cannot expose the same content.Ingester path... Proof / current artifact: See files X, Y, Z. Subagent found A, B, C. Next action: Implement interface in package N. Do not add new cache-mount flags yet.
```

> A concrete handoff-note schema (Decision / Why / Proof-artifact / Next action / explicit negative constraint) — and the dissent is equally informative: the user rejected it as bureaucratic overhead for sessions that were exploratory. Worth adopting for the plan→implementer boundary, not for every turn.

**HN user enraged_camel, describing his 'super plan' skill**

```
Super plan has the agent write the plan and then have it adversarially reviewed by three subagents, and hardened based on their feedback. I then read that plan and greelight it. ... The prompts contain broader contextual details (like what other tickets might be worked on in parallel, the boundaries, operational/environment constraints, and so on).
```

> The 'what other tickets are in flight, and where your boundaries are' clause is the specific mitigation for the contradictory-specs failure (alirezarezvani's backend-vs-product conflict). Concrete line for the implementer dispatch: name the sibling work units and the files this implementer may NOT touch.

**skills-hub.ai / claudedirectory.org SEO guides (LOW CREDIBILITY — no author, no evidence, included only because the phrasing is widely copied)**

```
You are done when: (a) tests pass, (b) lint passes, (c) the spec's checklist is all checked. ... Plan this change with the list of files to be edited, the specific functions to be modified in each, and the order of operations.
```

> This is the most-repeated advice in 2026 SEO content and I found NO validation for it anywhere — no benchmark, no A/B, no production post-mortem. It happens to be consistent with the evidence-backed principles above (verifiable exit criteria, exact file paths), so it is probably fine, but flag it honestly: it is popular repetition, not a finding.

### Approaches (10)

- **Orchestrator-only main agent (the main agent is forbidden to edit files)** — The top-level agent never uses Edit/Write/Bash for implementation. It reads the request, investigates, decomposes, writes tickets/plan units, dispatches implementer subagents, reads their summaries, and dispatches the next unit. Rationale given repeatedly: the plan and the implementation details compete for the same context, and once the main agent starts editing code its attention shifts and the plan decays. HN user vikramkr states the mechanism precisely: 'The orchestrator agent, if it was implementing everything, would end up deep into its context window where performance degrades steeply, and if you ran into issues early in the session you'd have to be concerned about whether whatever reasoning traces are in context are poisoning your later outputs.'
  - *Reported results:* Mixed and self-reported. enraged_camel (HN, Jul 2026) reports a full Fable-orchestrator → Linear ticket → Opus implementer → 3 adversarial plan reviewers → 3 code reviewers → browser QA → ship/no-ship pipeline that 'works incredibly well, and is almost completely hands off.' No numbers, no A/B. Counter-evidence: GitHub issue #23620 commenter cel66 reports the orchestrator LOST its 'project manager only' role constraint after 4 compactions and silently started implementing directly. So the pattern is known to decay in exactly the long sessions it exists to enable.
  - *Source:* https://news.ycombinator.com/item?id=49037996
- **Plan to a file, then implement in a NEW session with clean context** — Phase 1: agent scans the project and writes an implementation plan to a markdown file in the repo. Human reviews the file. Phase 2: a fresh session (or fresh subagent) is told to read that file and implement it. The explicit reasoning from HN user bel8: 'planning phase is when the LLM has to scan the entire project to understand what needs changing. This is where the context bloat comes from. If you split tasks into planning + implementation, the scanning phase is condensed into a single markdown file which keeps context lean.' The plan file, not the conversation, is the handoff medium.
  - *Reported results:* Most convergently-reported workaround in the whole corpus — arrived at independently by bel8 (HN), gck1 (HN), Imanari and waldopat (Ask HN SDD), cfunderburg (Ask HN SDD), meller_a (LaneConductor), and formally requested as a product feature in claude-code issue #71614 ('Plan mode: add a clear context & implement plan action'). No controlled comparison anywhere. Known failure mode: claude-code issue #12505 — the plan .md on disk goes stale and gets re-presented for the NEXT, unrelated task; 7+ users confirm, workaround is forcing deletion of the plan file.
  - *Source:* https://news.ycombinator.com/item?id=48772685
- **Put the instructions in the Agent tool's `prompt` parameter, not in the agent definition file** — Stop relying on CLAUDE.md, .claude/rules/, agent-definition markdown bodies, or hooks to reach the subagent. Restate every convention the implementer needs — build commands, file conventions, forbidden patterns, git identity, test command — inside the dispatch prompt itself.
  - *Reported results:* This is the strongest single practitioner finding I found. A heavy production user (GitHub user ThatDragonOverThere, 11 custom agents, daily use since Dec 2025) documents four systematically-tried approaches and their outcomes: (1) 'MANDATORY: Sub-Agent Workflow' block at the top of all 11 agent MDs — 'Sub-agents still don't follow it'; (2) made it Rule #1 in CLAUDE.md — 'Still ignored by spawned sub-agents'; (3) InstructionsLoaded hook — 'only fires for the main session, not sub-agents'; (4) memory-documentation instructions in agent MDs — 'sub-agents don't document anything.' Conclusion, verbatim: 'The **only** reliable way to get a sub-agent to follow instructions is to put them directly in the `prompt` parameter of the Agent tool call. Agent definition MDs and CLAUDE.md are effectively decorative for sub-agent behavior.' Corroborated independently by the dev.to production-orchestrator author ('If a specialist needs your coding conventions, those conventions go in the specialist prompt itself'), by issue #69283's forensic report, and by amurgshere's concrete case where an Explore subagent recommended exactly the path format that CLAUDE.md documented as broken.
  - *Source:* https://github.com/anthropics/claude-code/issues/12790
- **Task-shaped subagents, not role-shaped subagents** — Define subagents by the token-economics of the job, not by a persona. HN user lucraft: 'Don't make subagents for the different roles, make them to manage context for token heavy tasks... The ideal sub agent is one that can take a simple question, use up massive amounts of tokens answering it, and then return a simple answer.' The test is a compression ratio: input small, work huge, output small. A 'backend-engineer' persona fails this test; 'run the full test suite and report only the failing assertions' passes it.
  - *Reported results:* No benchmark. But the persona framing is directly attacked by multiple HN commenters: skimojoe ('I am sceptical if these persona based agents really make that much of a difference, and more "appear" to make a difference because of their talk style. Underneath is just a system prompt'), and wrs ('Telling the LLM that it is an experienced product manager doesn't make it an experienced product manager, it just makes it sound like one. This is like launching an entire team of "fake it til you make it" employees'). The alirezarezvani seven-persona-planner report is the concrete failure: role-shaped planners produced mutually contradictory specs.
  - *Source:* https://news.ycombinator.com/item?id=45181577
- **Hook-based context injection (SubagentStart + PreCompact)** — A ~40-line hook reads CLAUDE.md / rules files and injects them via `additionalContext` on every subagent spawn, and re-injects before compaction. Directly compensates for the fact that subagents don't inherit project rules and that compaction demotes rules from 'active constraints' to 'historical context'.
  - *Reported results:* Three practitioners in claude-code issue #59309 (phpmac, kcarriedo, hipvlady) independently converge on this as the correct fix for the rule-propagation case, and hipvlady — who was building a much heavier MESI-style coordinator — publicly concedes '40 lines beats a coordinator any day for that scope.' Documented gap: the injection is a snapshot at spawn time, so if CLAUDE.md changes mid-session a long-running subagent ships work violating the new rule. Contradicting datapoint: ThatDragonOverThere reports building exactly this SessionStart(compact) re-injection hook and 'Claude ignores it' — so the mechanism is not universally reliable.
  - *Source:* https://github.com/anthropics/claude-code/issues/59309
- **Model pinning per role (expensive planner, cheap implementer)** — Orchestrator/planner on the frontier model; implementer and mechanical subagents explicitly pinned to a cheaper model in frontmatter. cfunderburg (Ask HN): 'using strong models like Opus to write specs that cheaper models can implement, with built-in testing, linting, and coverage requirements (80%+).' vardalab runs the extreme version: frontier model plans and reviews, local LLMs implement in worktrees at ~180 tok/s.
  - *Reported results:* MEASURED, and it is the one config change with a real number behind it. Systima's proxy benchmark: parent on Opus, subagents inherited-Opus = 762,226 metered input tokens / 8m 0s; same task with Haiku-pinned subagents = 481,387 tokens / 3m 45s — '37 per cent fewer input tokens' and 'under half the wall time.' BUT two serious caveats from practitioners: (a) claude-code issue #52502, an Opus-orchestrator/Haiku-subagent setup still burned 35% of a 5-hour window in ~1 hour, and the reporter's /usage output suggested the `model: haiku` pin was being silently ignored; (b) stilesja (HN) burned $120 in 75 minutes because 'claude had "Forgotten" my directive to use cheaper models as appropriate for sub-agent tasks so I was running multiple instances of Fable at once.' Pin the model in frontmatter, never in prose.
  - *Source:* https://systima.ai/blog/subagent-tax
- **Shared on-disk state as the bus; every agent writes back to the plan file** — The plan/spec/task markdown files in the repo are the single source of truth, and each subagent is required to update the file when it finishes. HN user gck1: '/implement command acts as an orchestrator & plan mode... Every time /implement command is initiated, it has to create markdown file inside my own project, and then each subagent is also instructed to update the file when it finished working. This way, orchestrator can spot that agent misbehaved, and reviewer agent can see what developer agent tried to do and why it was wrong.' meller_a's LaneConductor makes it explicit: 'all state lives in Markdown files (plan.md, spec.md, index.md) rather than in any LLM's context window... The files are the shared context and the crash recovery mechanism.'
  - *Reported results:* Convergent from unrelated people (gck1, meller_a, rufasterisco who maps GitHub issues to committed .md files, a_t48's Fable closure-note format, kcarriedo's DECISIONS.md append-only ledger). Crucially it is also the ONLY mitigation that survives the three worst orchestrator failures documented in GitHub issues: silent subagent truncation (#73372, deliverable-on-disk check catches it), compaction amnesia (#23620), and blank-context retries (#80253, 'Reuse valid artifacts created by earlier attempts'). No benchmark. Real cost: kcarriedo notes CLAUDE.md is the wrong file for this because it 'grows unboundedly'; use a dedicated ledger.
  - *Source:* https://news.ycombinator.com/item?id=46532173
- **Read-only adversarial reviewer subagents** — Reviewer/critic subagents get `tools: Read, Grep` and nothing else. alirezarezvani: 'the reviewer can't write. Least privilege, even for a planning agent.' enraged_camel runs three adversarial subagents against the PLAN before implementation ('super plan'), then three more against the code, each on a different axis (test quality, regression risk, security).
  - *Reported results:* The one role that survives the sceptics. alirezarezvani's honest post concludes six of his seven agents were commodity work 'only the adversarial reviewer retained unique value.' Counter-signal worth taking seriously: patwolf (HN, Jul 2026) reports the review-subagent loop degrading into slop on Opus 5 — 'a simple SQL migration script with a single CREATE TABLE... After a few rounds of review, it ballooned into a complicated 200 line script.' And Anthropic's own Opus 5 guidance says to REMOVE 'use a subagent to verify' instructions because they cause over-verification.
  - *Source:* https://alirezarezvani.substack.com/p/my-seven-claude-code-subagents-did
- **Aggressive tool restriction on spawn to cut the fixed context tax** — Restrict the implementer/reviewer's tool list in frontmatter so the spawn doesn't pay for schemas it will never use. Also: add `Agent(Explore)` to the deny list to prevent uncontrolled fan-out.
  - *Reported results:* MEASURED and reproducible. claude-code issue #76045, with raw JSONs published: identical trivial prompt, `claude -p` default = 27,403 starting context tokens; `--tools Read,Glob,Grep` = 7,873; `--tools none` = 5,236; custom agent with `tools: []` frontmatter = 1,965. '~22k of the ~27.4k default headless floor' is built-in tool schemas. Author verified frontmatter is genuinely honored (a `tools: []` agent self-reports NO TOOLS) despite a UI display bug showing '(Tools: All tools)'. Systima independently recommends the `Agent(Explore)` deny-list entry.
  - *Source:* https://github.com/anthropics/claude-code/issues/76045
- **Depth cap on nesting (orchestrator → worker → sub-worker, stop at 3)** — Explicitly forbid implementers from spawning their own subagents beyond a fixed depth.
  - *Reported results:* Owain Lewis tested nested subagents on a real GitHub issue: 148,000 tokens across six runs, 21 minutes. Found NO depth guardrail in Claude Code — 'I tested the recursion depth on one of my own projects and got to about thirty levels' before cancelling. His rule: 'use the orchestrator, worker, sub-worker pattern, but don't go deeper than about three levels.' Notes Codex exposes a `max_depth` config that Claude Code lacks.
  - *Source:* https://newsletter.aiengineer.co/p/i-tested-nested-subagents-in-claude
