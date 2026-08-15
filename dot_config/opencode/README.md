# OpenCode Research Workflow

These global OpenCode V2 commands and file-backed agents support evidence-backed
research in the active project. They use an orchestrator-worker pattern:
independent scouts gather evidence in parallel, a verifier checks claims against
source material, and a synthesizer produces the final recommendation.

## Agents

| Agent | Role |
| --- | --- |
| `research/lead` | Defines scope and delegates bounded, non-overlapping work. |
| `research/scout` | Researches one track and writes one evidence card. |
| `research/verifier` | Checks claims against sources and writes a claim ledger. |
| `research/synthesizer` | Writes a cited report from verified claims only. |
| `research/auditor` | Checks the final report against verified claims and coverage. |

## Commands

| Command | Purpose |
| --- | --- |
| `/research/datasets <need>` | Research and rank datasets for a concrete use case. |
| `/research/topic <question>` | Research a broader factual or technical question. |
| `/research/verify <artifact-dir>` | Verify source-backed claims in a prior research run. |
| `/research/synthesize <artifact-dir>` | Turn verified evidence into a decision-ready report. |

The entrypoint commands use the `research-workflow` plugin to create a unique
`.research/<slug>/<timestamp>/` run in the active project:

```text
manifest.md       Plugin-managed run state and evidence revision
brief.md          Scope, thesis, criteria, vetoes, and stopping rules
coverage.md       Required questions and their current evidence status
evidence/         One card per scout with stable source and claim IDs
contradictions.md Material conflicts between claims
verification.md   Claim-level verification and verified revision
report.md         Final cited recommendation
report-audit.md   Independent PASS, REVISE, or BLOCKED verdict
```

Use the entrypoint for normal work. Run `/research/verify` or
`/research/synthesize` separately only to resume, update, or challenge a prior
run. Review artifacts before sharing or committing them.

The plugin exposes `research_workflow_init`, `research_workflow_check`, and
`research_workflow_advance`. It rejects invalid stage transitions, incomplete
planning, empty collection, stale verification, unresolved required coverage,
and completion without a passing report audit. Workers communicate through
their assigned artifacts rather than copied transcripts.

## Prerequisite

Scouts need a search tool, and OpenCode's is off by default: `websearch` only
exists when `OPENCODE_ENABLE_EXA` is set to a truthy value (or on the opencode
provider, which we do not use). Without it scouts have only `webfetch` and no
way to find a URL to fetch, and the failure is quiet — an agent reports "no
websearch tool", which reads like a working denial rather than a missing
capability.

Three layers now keep that from happening silently:

1. The managed `~/.zshrc` block (`modify_dot_zshrc`) exports
   `OPENCODE_ENABLE_EXA=1`, so any opencode launched from a fresh shell has it.
   `opencode2` (the v2/next build in `~/.opencode/bin`) is additionally wrapped
   in a function that sets the variable per-invocation, so it stays on even if
   the export is ever removed.
2. `research_workflow_init` and `research_workflow_check` warn when the
   variable is unset, before any scout is dispatched, and the lead is
   instructed to block the run on that warning.
3. The scout aborts and reports the missing tool instead of substituting
   webfetch-only guessing.

A shell opened before the zshrc block was applied still lacks the variable —
relaunch the shell (or `exec zsh`) if the lead reports the run blocked on it.

## Who can do what

Enforcement is the frontmatter `permission` map, never prose. Each agent starts
from `"*": deny` and allows only the tools and paths its role needs, so it
cannot write outside its lane even if its prompt is misread. Note the key is
`permission`, singular — the `permissions:` array form is valid only in
`opencode.json` and is dropped without warning in markdown frontmatter.

| | Web | Writes | Dispatches |
| --- | --- | --- | --- |
| `lead` | none | `brief.md`, `coverage.md` | the four research agents only |
| `scout` | search + fetch | its own evidence card, `contradictions.md` | none |
| `verifier` | fetch only | `verification.md` | none |
| `synthesizer` | none | `report.md` | none |
| `auditor` | none | `report-audit.md` | none |

The lead has no web access, so every fact reaching the user passes through a
scout's claim ID and the verifier's ledger. The verifier can fetch but not
search, because finding a different source that agrees is not verification of
the cited one. `manifest.md` is written by the plugin and by nobody else.

`research-sources-and-prompts.md` records the external prompts these were built
from and the decisions worth not re-litigating. Read it before editing an agent.
