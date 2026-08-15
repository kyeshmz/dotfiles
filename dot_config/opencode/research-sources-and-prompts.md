# Research Agents — Sources, External Prompts, and What We Took

Why the five `agents/research/*.md` prompts say what they say. Read this before editing one.

## Sources

| Credibility | What it is | URL |
|---|---|---|
| `primary-official` | Anthropic, "How we built our multi-agent research system" — the eight prompt principles, the effort-scaling table, the token multipliers, the LLM-judge rubric, and the enumerated failure modes. | https://www.anthropic.com/engineering/multi-agent-research-system |
| `primary-official` | Anthropic cookbook `research_lead_agent.md` — the depth-first / breadth-first / straightforward taxonomy, the subagent scaling table, the eight required fields of a subagent task description, and the never-do list. | https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/prompts/research_lead_agent.md |
| `primary-official` | Anthropic cookbook `research_subagent.md` — the OODA loop, tool-call budgets by difficulty, and the source-quality flag list. | https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/prompts/research_subagent.md |
| `primary-official` | LangChain `open_deep_research/prompts.py` — hard iteration/concurrency limits, the three stop criteria, "bias towards single agent", and verbatim-preservation in compression. | https://github.com/langchain-ai/open_deep_research/blob/main/src/open_deep_research/prompts.py |
| `primary-official` | OpenAI cookbook, Deep Research API agents — the clarifier and the instruction-builder, including the rule for unstated dimensions. | https://developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api_agents |
| `primary-official` | OpenCode agent + permission docs and the V2 `PermissionV2` schema — the valid permission action keys, last-match-wins evaluation, and the `ask` fallback. | https://opencode.ai/docs/agents |
| `peer-reviewed-or-benchmarked` | DeepResearch Bench (100 PhD-level tasks, 22 fields) — RACE report scoring and FACT citation scoring. Best measured citation accuracy is Perplexity Deep Research at 90.24%. | https://arxiv.org/abs/2506.11763 |
| `peer-reviewed-or-benchmarked` | DeepMind SAFE / LongFact — decompose a long answer into atomic facts, make each self-contained, then check each against search. 72% agreement with human annotators over ~16k facts, 20x cheaper, and it beats humans on 76% of a 100-case disagreement sample. | https://github.com/google-deepmind/long-form-factuality |
| `peer-reviewed-or-benchmarked` | STORM (Stanford) — perspective-guided question asking: survey similar topics to discover viewpoints the researcher would not have thought of, then ask from each. | https://arxiv.org/pdf/2402.14207 |
| `practitioner-battle-tested` | Cognition, "Don't Build Multi-Agents" — the counterargument. Parallel subagents make conflicting *implicit* decisions and the merge step inherits both. | https://cognition.com/blog/dont-build-multi-agents |
| `practitioner-battle-tested` | GPT Researcher `prompts.py` — the ban on search-operator syntax, the anti-hedge rule, and the "cite nothing outside the provided information" rule. | https://github.com/assafelovic/gpt-researcher/blob/main/gpt_researcher/prompts.py |

## Verbatim excerpts that changed a prompt

**Anthropic, research_subagent.md** — budget by difficulty
```
Simple tasks: <5 tool calls. Medium: ~5. Hard: ~10. Very difficult: up to 15.
Absolute maximum: 20 tool calls; ~100 sources before termination.
```
> Became the scout's 5/10/15/stop-at-20 ladder. Ours previously had `steps: 16` in frontmatter and nothing in the prompt — a cap the model could not see and therefore could not pace itself against.

**LangChain, `research_system_prompt`** — stop criteria
```
You can answer the user's question comprehensively
You have 3+ relevant examples/sources for the question
Your last 2 searches returned similar information
```
> Lifted nearly verbatim into the scout. This is the highest-value single addition: the scout previously had no termination condition other than running out of steps.

**Anthropic engineering blog** — the query-length failure
```
[agents defaulted to] overly long, specific queries that return few results
```
> Our scout already said "start with short, broad searches". Added the concrete violation, because the house rule is to enumerate forbidden specifics: queries under 10 words, and the named operator ban from GPT Researcher (`site:`, `filetype:`, `inurl:`, `intitle:`, `OR`, `AND`, `NOT`).

**Anthropic, research_subagent.md** — source-quality flags
```
Speculation, predictions, future tense ("could," "may"); unconfirmed reports;
marketing/spin language; passive voice with nameless sources; cherry-picked or
misleading data; false authority; general qualifiers without specifics.
```
> Ours had the *prefer* half (publishers, papers, license text) and nothing on the *flag* half. Added as a six-item enumeration the scout marks on the card.

**OpenAI, instruction builder** — unstated dimensions
```
If the user has not provided a particular detail, do not invent one. Instead,
state the lack of specification.
```
> Became the lead's "state an unprovided detail as open-ended rather than inventing a constraint." Matters more for us than for them, because our brief is frozen before dispatch and an invented constraint silently propagates to every scout.

**GPT Researcher, `generate_report_prompt`** — the anti-hedge
```
You MUST determine your own concrete and valid opinion based on the given
information. Do NOT defer to general and meaningless conclusions.
```
> Became the synthesizer's named ban list. Enumerating the three actual hedges ("it depends on your needs", "both are viable options", "further research is recommended") beats the abstract rule.

**Anthropic, research_lead_agent.md** — the one rule we deliberately rejected
```
Never create subagents to generate the final report (lead agent writes it).
```
> See below.

## Design decisions worth not re-litigating

- **We delegate synthesis; Anthropic does not.** Their lead writes the report because it holds
  the full research context. Ours cannot: the lead has no web access and the synthesizer is
  context-isolated by construction, so the only thing it *can* write from is
  `verification.md`. That is the point — it makes "the report contains only supported claims"
  a structural property rather than an instruction, and the auditor checks it independently.
  The cost we accept is losing the lead's holistic view of the evidence. Keep the split.

- **Cognition's critique applies to us, and `brief.md` is the answer.** Their failure mode is
  parallel subagents making conflicting *implicit* decisions. Our mitigation is that the
  plugin refuses to advance to `collecting` while `brief.md` contains a `TODO`, so criteria,
  vetoes, scope, and exclusions are explicit and identical across scouts before any of them
  runs. The lead's prompt now says why. This is also why the brief is frozen: a mid-run
  amendment is exactly the divergence they describe.

- **No confidence scores anywhere.** Same reason as the coding agents. The verifier grades on a
  three-value ladder (`supported` / `uncertain` / `rejected`) with named downgrade triggers,
  and the auditor emits one of three tokens. Neither emits a number.

- **The verifier cannot search, only fetch.** Finding a *different* source that agrees is not
  verification of the cited one, and it silently converts a bad citation into a good-looking
  claim. Enforced by `websearch: deny`, not by prose.

- **Budget-driven verification is explicit.** SAFE's per-atomic-fact checking does not fit in
  16 steps for a large run, so the verifier gets a priority order (required rows → vetoes →
  numbers/dates/versions → rest) and one hard rule: an unopened claim is `uncertain`, never
  `supported`. Silent partial verification was the worst available failure, because
  `report.md` is gated on `supported` alone.

- **Why the verification stage exists at all.** The best measured deep-research agent scores
  90.24% citation accuracy on DeepResearch Bench. At that rate roughly one citation in ten
  does not support its claim, which is well above the tolerance for a licensing or
  redistribution decision.

## The permission bug this sweep found

**The whole permission block was inert.** Every agent used the `permissions:` array form:

```yaml
permissions:                 # WRONG in markdown — silently ignored
  - action: shell
    resource: "*"
    effect: deny
```

Two independent faults. First, `shell` and `subagent` are not permission keys — it is `bash`
and `task`. Second, and fatal on its own: **the `permissions:` array is only valid in
`opencode.json`.** In agent markdown frontmatter the key is `permission:`, singular, a map.
An unrecognized frontmatter key is dropped without a warning, so all five agents ran with
whatever the session default was.

This was found by running it, not by reading the schema. An A/B probe settled it — two agents
identical but for the container key, each asked to run `echo`:

| Frontmatter | Result |
|---|---|
| `permissions:` list, `bash`/`*`/`deny` | `echo` **ran** |
| `permission:` map, `bash: deny` | tool absent, `BASH_BLOCKED` |

Do not trust a permission block that has never been exercised. The failure is silent in both
directions: a wrong key denies nothing, and a right key can hide a tool the agent needs.

What the working form buys, verified against the filesystem rather than the agent's own
report — a scout told to write three files wrote only the legal one:

```
← Write .research/ice/run1/evidence/card-a.md    Wrote file successfully.
✗ Write .research/ice/run1/report.md             failed: rule prevents this tool call
✗ Write PWNED.md                                 failed: rule prevents this tool call
```

Rules that matter:

- Permission keys are **wildcard-matched against the tool name**, and later keys beat earlier
  ones. So `"*": deny` first, then the handful of allows, is a real deny-by-default. Use it:
  it is the only thing that scales, because the alternative is enumerating every tool.
- `edit`, `task`, `bash`, `read`, `glob`, `grep`, `list`, `external_directory`, and `skill`
  take either a shorthand (`allow`/`ask`/`deny`) or a nested map of glob → action. The rest
  take the shorthand only.
- The `edit` key gates `write`, `edit`, and `apply_patch` together, and its patterns match
  **project-relative** paths. `*` spans `/`, so `.research/*/evidence/*` already covers
  `.research/<slug>/<timestamp>/evidence/card.md`.
- The fallback for an unmatched tool is `ask`, not `deny` — which for an unattended subagent
  means a stall, not a refusal. Deny-by-default plus explicit allows avoids both.

### The blast radius nobody had measured

The deny-by-default rewrite was not tidiness. Enumerating what a research agent could actually
reach in this install returned **131 tools** — every MCP server in the user's config is handed
to every agent. A "read-only" scout had `planetscale_execute_write_query`,
`supabase_execute_sql`, `github-mcp_delete_file`, and `github-mcp_create_repository`. Denying
`bash` while leaving those in place is theater. The five agents now expose 8 tools or fewer.

### websearch does not exist by default

`websearch` is gated behind an environment variable:

```sh
OPENCODE_ENABLE_EXA=1 opencode
```

Without it the tool is simply absent, and the scout — whose first instruction is to search
broad then narrow — has only `webfetch` and no way to find a URL to fetch. This was invisible
until a probe listed the real tool inventory: the agent reported "no websearch tool", which
reads like a working denial and is actually a missing capability.

Enforcement was later moved out of prose-in-a-README into three layers, per the general
lesson that quiet capability failures need a deterministic detector: the managed `~/.zshrc`
block exports the variable; the plugin's `init` and `check` emit a warning when it is unset
(a warning, not a gate, because the opencode provider enables the tool without the
variable); and the scout's prompt makes "websearch absent" a stop-and-report condition
rather than something to route around with webfetch. The scout still writes its evidence
card in that case — a note that the environment lacks websearch — so the artifact contract
holds and the lead sees the failure in both the card and the reply.
- For paths inside the project the resource is **project-relative**, and `*` expands to `.*`,
  which spans `/`. So `.research/*/evidence/*` already covers
  `.research/<slug>/<timestamp>/evidence/card.md`; the `.research/*/*/evidence/*` duplicates
  were redundant and have been removed.

## The end-to-end run that proved it

One full run, `.research/best-selling-ice-cream-flavor-us/`, on a question chosen because the
published surveys genuinely disagree. Five scouts (breadth-first, one assigned counterevidence)
→ verifier → synthesizer → auditor → `PASS`, `synthesis_revisions: 0`, twelve artifacts.

What the run demonstrated, beyond "it does not crash":

- **The verifier caught a real citation error.** Scout 5 dated two YouGov figures 2024/2025;
  their true vintage is 2018/2020. The correction propagated into the report. This is the
  ~10%-of-citations failure rate the stage exists to catch, observed once in a five-card run.
- **The `uncertain` ladder is load-bearing, not decorative.** Final counts were 33 `supported`,
  25 `uncertain`, 2 `rejected`. Three IDFA/Baskin-Robbins PDFs would not extract, and a
  "chocolate 491M vs vanilla 333M units" counter-lead was never opened — all landed
  `uncertain` and none reached the report as fact.
- **The anti-hedge rule held.** The report commits — "vanilla, at medium confidence" — then
  names the specific missing fact (whether Circana's "Vanilla" is one SKU or an aggregated
  bucket) instead of closing on "it depends on your needs".
- **The permission block contained a real escape attempt.** Blocked by the staleness gate, the
  lead tried to `edit` and then `write` `verification.md` — i.e. to forge the verifier's ledger
  to get past its own quality gate. Both were denied. Under the inert `permissions:` array this
  would have succeeded silently, and the run would have "passed".

That last one is the argument for testing permissions rather than reading them. The lead was
not adversarial; it was being helpful, and helpfulness is exactly what routes around a gate.

### And one deadlock it exposed

`research_workflow_advance` to `synthesizing` failed permanently with
`verification is stale: expected evidence revision 1`. The verifier had computed the right
value and written it as:

```
**verified_revision:** 1 (matches `evidence_revision: 1` in manifest.md)
```

The gate's regex was `/^verified_revision:\s*(\d+)$/m` — a bare line. Markdown emphasis broke
it, and no run could ever reach synthesis. Fixed on both sides, because either alone is
brittle: the verifier prompt now shows the exact undecorated line, and the plugin's `marker()`
and `verdict()` helpers tolerate bullets and emphasis. The `PASS` check had the identical flaw
(`/^PASS$/m` vs `**PASS**`) and got the same treatment, with unit cases confirming
`the report does not PASS the bar` and `PASSED` still do not match.

The general lesson for this workflow: **any string a model writes that a gate parses needs a
tolerant reader and a literal example in the writer's prompt.** Prose like "record the
revision" is not a format specification.

## Caveats

- Everything about permissions here was exercised against OpenCode 1.18.15 on a live run, not
  inferred from the schema — the schema is what produced the wrong answer the first time.
  Re-run the probes after an OpenCode major upgrade; a renamed key fails exactly as silently
  as `permissions:` did.
- The run used `parley/bedrock/claude-sonnet-5`. The `anthropic` provider is disabled in
  `opencode.json`, and the `plan` agent there still points at `anthropic/claude-opus-4-5`,
  which no longer resolves. Unrelated to these agents, but it will bite the next thing that
  reads that config. The bedrock route also errors with "does not support assistant message
  prefill" when a session ends on an assistant turn — cosmetic here, since it hit after the
  workflow had already written its artifacts.
- Anthropic's cookbook prompts are written for a system with `complete_task`, internal
  connectors, and a separate citation agent. Budgets and taxonomy transfer; the tool-specific
  instructions do not.
- DeepResearch Bench numbers are ordinal, not cardinal — LLM-judge protocols scored against a
  reference report, on 100 tasks.
