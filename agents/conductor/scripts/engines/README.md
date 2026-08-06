# Engine adapters

One file per engine. `agent-run.sh` dispatches to these by name, so every
role script (fanout, worker, tests, review) is engine-agnostic — adding an
engine means adding one file here and nothing else.

## Contract

Each adapter is invoked as:

```
engines/<name>.sh <label> <model> <prompt-file> <work-dir> [--write]
```

- `label`      identifies the step in the token ledger
- `model`      engine-native model id (see below — they are NOT interchangeable)
- `prompt-file` file holding the full prompt
- `work-dir`   where artifacts land
- `--write`    allow repo edits. Omit for read-only roles.

Env in: `RUN_DIR`, `REPO`, and optionally:

| Var | Meaning |
|---|---|
| `AGENT_DEF` | File holding a role definition's body, produced by `agent-def.py` from `agents/<role>.md`. The agent that runs IS that role. |
| `AGENT_TOOLS` | Comma-separated tool allowlist from the same definition's frontmatter. When set it wins over the adapter's own default. |
| `SUBAGENTS_JSON` | `--agents` payload, so a role that dispatches (the planner) reaches the roles it dispatches. |

`AGENT_DEF` is where an engine's real ceiling shows. `claude-code` has a system
prompt channel (`--system-prompt-file`) and a tool allowlist, so a definition
runs there as written and a withheld tool is genuinely absent. `opencode` and
`codex` have neither on their exec paths, so they **prepend** the definition to
the prompt: same text, weaker separation, and no way to actually remove a tool.
Roles whose boundaries are load-bearing — the planner that must not dispatch
while planning, the reviewer that must not edit what it reviews — belong on
`claude-code`. Ignoring `AGENT_DEF` entirely is not an option: the role would
silently run as a generic assistant, which is the failure the definitions exist
to prevent.

**Must produce:**

1. `<work-dir>/last.txt` — the assistant's final text, nothing else. Callers
   parse this; if an engine streams, the adapter reassembles it.
2. `$RUN_DIR/tokens/<label>.json` — normalized usage, this exact shape:

```json
{"label":"...","engine":"...","model":"...","steps":1,"cost_usd":0.0,
 "errors":[],"input_tokens":0,"output_tokens":0,"reasoning_tokens":0,
 "cache_read_tokens":0,"cache_write_tokens":0,"total_tokens":0}
```

Normalizing here is what keeps `token-report.py` free of per-engine logic.
`errors` must be populated on failure — a run that spends nothing because it
hit a quota is not a free success, and the ledger has to be able to say so.

3. Exit `0` on success, non-zero on failure. Callers decide whether that is
   fatal.

## Model ids are engine-specific

| Engine | Format | Example |
|---|---|---|
| `opencode` | `provider/model` | `parley/openai/gpt-5.6-sol` |
| `codex` | bare model | `gpt-5.6-terra` |
| `claude-code` | bare model | `claude-opus-5` |

Passing an opencode-style id to codex fails at the API, not at parse time —
`agent-run.sh` shape-checks the pairing up front so that surfaces early.

## Counter semantics differ

Worth knowing when writing a new adapter:

- **opencode** emits per-step `step_finish` counters → **sum** them.
- **codex** emits cumulative `total_token_usage` → take the **max**.

Summing cumulative counters multiply-counts; maxing per-step counters
undercounts. Both are silent failures, so get it right per engine.
