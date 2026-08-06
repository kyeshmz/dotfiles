# AGENTS.md — editing the agent definitions

This directory is the source of truth for a set of coding-agent role definitions. One
subdirectory per role, each holding the definition plus its own `AGENTS.md` naming the
invariants that role's file must preserve. **Read the role's own `AGENTS.md` before editing
its definition** — the closest one to the file you are editing wins.

These files are prompts that run unattended. A line that changes no behavior is worse than
absent, because it dilutes the lines that do.

## Invariants for every role definition

- **Never add a `model:` field.** No definition declares a model; every one inherits the
  session's engine. This is what makes the set engine-agnostic and is why there is one
  implementer rather than one per vendor. Model choice belongs to the caller.
- **Never name a model or vendor** in a description, a body, or anything the agent emits —
  no "Opus", "Sonnet", "Codex", "GPT", "powered by". Naming the CLI a role shells out to is
  the only exception, and no current role does.
- **`description` is a routing string**, not a bio. It is the only text a parent reads when
  deciding to delegate, and it stays in the parent's context permanently. Two sentences: when
  to use it, and when NOT to. Keep the "Do NOT use for…" half.
- **Enforcement lives in `tools` / `disallowedTools`, never in prose.** If a rule must not be
  skipped, remove the capability. A sentence asking an agent not to do something it can do
  will lose to helpfulness priors at the exact moment it matters.
- **Only these frontmatter fields exist:** `name`, `description`, `tools`, `disallowedTools`,
  `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`,
  `background`, `effort`, `isolation`, `color`, `initialPrompt`. Anything else is silently
  ignored. `name` and `description` are the only required ones. An invented field is a bug
  that fails quietly.
- **Identity is `name:`, not the filename.** Renaming a file is safe; changing `name:` breaks
  `/pipeline`, conductor, and anything else that dispatches by name.
- **Numbers, not adjectives**, wherever behavior is bounded: "at most 5 findings", "2 attempts",
  "under 400 words". "Be thorough" is not an instruction.
- **Enumerate forbidden specifics, not classes.** "Never write 'based on your findings'" beats
  "avoid vague references" — every source that bounds behavior does it by naming the violation.
- **Every reviewer keeps a single-token verdict line** on its own line. Callers branch on it.
  Changing a token means changing every caller; see `../dot_claude/commands/pipeline.md`.

## The pruning test

Before adding a line, ask: *would removing this cause a mistake?* If not, cut it. Bloated
instruction files measurably reduce adherence to the instructions that matter — one study found
LLM-generated context files reduced task success ~3% while raising cost 20%+. Length targets
live in each role's own `AGENTS.md`.

## Where things live

```
sync.sh                     installs this tree into ~/.claude, then verifies
AGENTS.md                   this file
<role>/<role>.md            the definition — source of truth
<role>/AGENTS.md            invariants for editing it
skills/handoff-contract/    the planner↔implementer contract, preloaded into both
commands/pipeline.md        the slash command that drives the roles
research/                   the evidence these were built from; 00 is the spec
conductor/                  unattended lanes that load these same definitions
```

## Installing a change

`~/.claude` is a **build output**. This tree is the source; never edit `~/.claude/agents/*.md`
directly, because the next sync overwrites it.

```sh
./sync.sh            # install, then verify
./sync.sh --check    # verify only; non-zero exit if ~/.claude has drifted
./sync.sh --dry-run  # show what would change
```

The live layout is flat; only this source tree uses subdirectories. `sync.sh` deliberately does
not copy the per-role `AGENTS.md` files — `~/.claude/agents` is scanned recursively for subagent
definitions, and a markdown file without agent frontmatter there is at best ignored and at worst
parsed as a broken agent. The script fails if one appears.

## Verifying a change

`./sync.sh --check` runs all of these and exits non-zero on any failure:

- every role name a caller dispatches resolves
- no definition declares a `model:`
- no description names a model or vendor
- no stray `AGENTS.md` under `~/.claude/agents`
- the `handoff-contract` skill exists at the path both definitions reference
- the dispatch template has not leaked back out of the skill into `planner.md`

Conductor loads the same definitions, so check it too after a rename:

```sh
cd conductor && for r in planner implementer inspector security-consultant performance-consultant; do
  python3 scripts/agent-def.py "$r" --agents-dir .. --out-dir /tmp/adcheck >/dev/null || echo "FAIL: $r"
done
```

## Repo conventions

There is no build, test, lint, or typecheck command here — this is a chezmoi-managed dotfiles
repo of markdown and shell. Verification is the grep assertions above plus `bash -n` on scripts
and a YAML parse on `conductor/workflows/*.yaml`.

Do not commit unless asked.
