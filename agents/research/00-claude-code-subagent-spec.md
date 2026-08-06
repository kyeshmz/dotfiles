# Claude Code Subagent Spec — Verified Facts

Fetched from <https://code.claude.com/docs/en/sub-agents> on 2026-07-28. These are the
mechanical constraints every agent definition in this directory must satisfy. Where the
research briefs and this file disagree, **this file wins** — it is the primary spec.

## Frontmatter fields

Only `name` and `description` are required.

| Field | Notes |
|---|---|
| `name` | Required. Lowercase letters and hyphens. Identity comes from this field, **not the filename**. Hooks receive it as `agent_type`. Must be unique across the whole `.claude/agents/` tree — duplicates load only one, chosen by filesystem read order. |
| `description` | Required. When Claude should delegate to this subagent. This is the routing string and the only text the parent reads when deciding to delegate. |
| `tools` | Allowlist. Inherits every subagent-available tool if omitted. If no entry resolves to a real tool the subagent **fails to launch**. Don't list `Skill` to preload skills — use the `skills` field. |
| `disallowedTools` | Denylist. Applied *before* `tools`. A tool in both is removed. |
| `model` | `sonnet`, `opus`, `haiku`, `fable`, a full ID (`claude-opus-5`), or `inherit`. Defaults to `inherit`. |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, `manual`. Ignored for plugin subagents. |
| `maxTurns` | Max agentic turns before the subagent stops. |
| `skills` | Skills preloaded into context at startup — **full content injected**, not just the description. |
| `mcpServers` | MCP servers for this subagent. |
| `hooks` | Lifecycle hooks scoped to this subagent. |
| `memory` | `user`, `project`, or `local`. Enables cross-session learning. |
| `background` | `true` to always run as a background task. As of v2.1.198 subagents run in the background **by default**. |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max`. Overrides session effort. |
| `isolation` | `worktree` for an isolated repo copy, branched from the default branch. Auto-cleaned if unchanged. |
| `color` | `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`. |
| `initialPrompt` | Auto-submitted first user turn when run as the main session agent (`--agent`). |

## Tool availability — two filters

Subagents inherit main-conversation tools, narrowed by two filters.

**Filter 1 — removed from every subagent, even if listed in `tools`:**
`Agent` (only when at the depth limit), `AskUserQuestion`, `EndConversation`, `EnterPlanMode`,
`ExitPlanMode` (unless `permissionMode: plan`), `ScheduleWakeup`, `TaskOutput`,
`WaitForMcpServers`, `Workflow`.

**Filter 2 — background subagents** (the default) keep every MCP tool but only these built-ins:
`Read`, `Grep`, `Glob`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`,
`WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`,
`TaskStop`, `SendMessage`, `Artifact`. Everything else is stripped silently.

`Agent` and `ExitPlanMode` are **exempt from filter 2** — they follow filter 1's conditions
wherever the subagent runs. So a background subagent can still spawn subagents.

Consequence for this directory: `LSP` is not in the filter-2 list, so a background subagent
cannot rely on it. Use `Grep`/`Glob` for symbol search.

## Nested delegation

- A subagent **can** spawn its own subagents, up to **three layers below the main
  conversation** by default. At the limit, `Agent` is withheld and the subagent does the work
  itself.
- The docs name this exact use case: *"a reviewer subagent that dispatches a verifier per
  finding, so the intermediate output never reaches your main conversation."* This is the
  `security-consultant` design, explicitly blessed.
- Only the top-level subagent's summary returns to the caller.
- Configurable via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (v2.1.217+).
- `Agent(agent_type)` allowlist syntax only applies to a main-thread agent (`claude --agent`);
  inside a subagent definition the parenthesised type list is **ignored** — listing plain
  `Agent` is what grants the capability.

## Naming and invocation

- **`Task` was renamed to `Agent` in v2.1.63.** `Task(...)` still works as an alias, but new
  files should say `Agent`.
- Subagents receive only their own system prompt plus basic environment details — **not** the
  full Claude Code system prompt, and **not** the parent's conversation history.
- `.claude/agents/` is scanned recursively; subfolders don't affect identity (except in
  plugins, where `agents/review/security.md` registers as `plugin:review:security`).
- A subagent starts in the main conversation's cwd. `cd` does not persist between Bash calls.

## Model resolution order

1. `CLAUDE_CODE_SUBAGENT_MODEL` env var
2. Per-invocation `model` parameter
3. The definition's `model` frontmatter
4. The main conversation's model

Subagents inherit the main conversation's extended-thinking setting (v2.1.198+); there is no
per-subagent thinking toggle.

## What loads into a subagent at startup

Verified, and it **corrects a claim in the research briefs**. A non-fork subagent's initial
context contains:

- **Its own system prompt** (the markdown body) plus environment details — *not* the full
  Claude Code system prompt.
- **The delegation prompt** the parent wrote.
- **CLAUDE.md files — every level of the hierarchy the main conversation loads**, including
  `~/.claude/CLAUDE.md`, **project rules (`.claude/rules/`)**, `CLAUDE.local.md`, and managed
  policy files. Only the built-in `Explore` and `Plan` agents skip this, and there is no
  frontmatter field to change that.
- **Git status** snapshot from the start of the parent session.
- **Preloaded skills** named in the `skills` field (full content).
- **Sibling roster** (only when `SendMessage` is in `tools`).

Never reaches a non-fork subagent: the parent's conversation history, the parent's **auto
memory** (use the `memory` field for the subagent's own), output style, and the parent's
context-window size.

> **Correction to sweep 2.** The research reported a practitioner claim that "agent definition
> MDs and CLAUDE.md are effectively decorative for sub-agent behavior." As a claim about
> *loading*, that is **false** — CLAUDE.md and `.claude/rules/` demonstrably load into custom
> subagents. The claim survives only as one about *adherence*, which the docs themselves
> support: instructions are "context rather than enforced configuration" with "no guarantee of
> strict compliance."
>
> Consequences: (1) the planner's rule to copy conventions verbatim into the plan is still
> right, but justify it by adherence and salience, not by non-delivery; (2) the performance
> consultant's `.claude/rules/` emission **does** reach the implementer subagent, so the rules
> ladder is sound; (3) enforcement that must not be skipped belongs in hooks or permissions,
> never in prose — the docs say this explicitly.

## `.claude/rules/` — verified format

- Location: `<repo>/.claude/rules/*.md`, discovered **recursively**; also user-level
  `~/.claude/rules/` (loaded before project rules, so project rules win).
- Rules **without** `paths:` frontmatter load unconditionally at launch, at the same priority
  as `.claude/CLAUDE.md`.
- Rules **with** `paths:` load only when Claude works with matching files:

  ```markdown
  ---
  paths:
    - "src/api/**/*.ts"
    - "lib/**/*.{ts,tsx}"
  ---
  ```

- Glob patterns support brace expansion. The whole `paths` list shares a budget of 1,000
  expanded patterns / 4 MiB; over-budget patterns are used unexpanded and match nothing.
  A `[` that isn't a valid bracket expression makes that pattern match nothing.
- Symlinks in `.claude/rules/` are supported and resolved.
- Size guidance from the docs: **target under 200 lines per CLAUDE.md file**; longer files
  "consume more context and reduce adherence."
- Skills (`.claude/skills/<name>/SKILL.md`) load **on demand**, unlike rules — the right home
  for multi-step procedures that shouldn't sit in context permanently.

## AGENTS.md — the cross-tool standard

From <https://agents.md/>, fetched 2026-07-28. Relevant because these definitions are meant to
be engine-agnostic, and `AGENTS.md` is the only instructions format that reaches every engine.

- "A README for agents": plain Markdown at the repo root, **no required fields**, any headings.
- Suggested sections: project overview, build and test commands, code style, testing
  instructions, security considerations, commit/PR guidelines.
- **Nested resolution:** "the closest AGENTS.md to the edited file wins; explicit user chat
  prompts override everything." This gives portable directory-level scoping without any
  vendor-specific glob frontmatter.
- Read natively by 20+ tools, including OpenAI Codex, Cursor, VS Code, GitHub Copilot, Aider,
  Zed, Warp, Devin, Jules.

**Claude Code does not read `AGENTS.md`.** It reads `CLAUDE.md`. The documented bridge is an
import:

```markdown
@AGENTS.md

## Claude Code
Use plan mode for changes under `src/billing/`.
```

or a symlink (`ln -s AGENTS.md CLAUDE.md`) when nothing Claude-specific is needed. On Windows a
symlink needs Administrator or Developer Mode, so prefer the import.

`/init` reads `.cursor/rules/`, `.cursorrules`, and `.github/copilot-instructions.md` and folds
them into the generated `CLAUDE.md`. With `CLAUDE_CODE_NEW_INIT=1` it also reads `AGENTS.md`,
`.devin/rules/`, `.windsurf/rules/`, `.windsurfrules`, and `.clinerules`.

## Local consumers

`~/.claude/commands/pipeline.md` dispatches agents **by `name`**: `planner`, `implementer`,
`inspector`, `codex-implementer`, `codex-reviewer`. Renaming any of those breaks `/pipeline`.
