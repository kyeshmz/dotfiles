#!/usr/bin/env python3
"""Resolve a role name to the agent definition that already exists on disk.

The `.md` files under `agents/` are the source of truth for what each role
is. This reads one of them, strips the frontmatter, and hands back the body
(as a file the engine adapters can pass verbatim as a system prompt) plus
the `tools:` and `model:` the definition declares.

Nothing here paraphrases a definition. If a role's behaviour needs to
change, the `.md` changes and every lane picks it up on the next run —
which is the entire reason the prompts are not inlined in the YAML.

Usage:
    agent-def.py <role> --out-dir DIR [--agents-dir DIR]
                        [--drop-tools Agent,Write] [--model M]
    agent-def.py --agents-json <role>[,<role>...] [--agents-dir DIR]

The first form prints one JSON object:
    {"role","path","body_file","tools","model","description"}

`tools` is the comma-joined allowlist to hand the engine; `model` is the
resolved model id (the frontmatter alias mapped through MODEL_ALIASES).

The second form prints the `--agents` payload `claude -p` accepts, so a
role that dispatches (the planner) reaches the roles it dispatches with
their real definitions rather than whatever happens to be installed in
~/.claude/agents on the machine running the lane.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

# Frontmatter carries an alias, never a model id — an agent definition that
# names a specific model goes stale the moment the fleet moves. The mapping
# lives here, in the one place a lane can override it.
MODEL_ALIASES = {
    "fable": "claude-fable-5",
    "opus": "claude-opus-5",
    "sonnet": "claude-sonnet-5",
    "haiku": "claude-haiku-4-5-20251001",
    "inherit": "",
}


def search_paths(agents_dir: pathlib.Path, role: str) -> list[pathlib.Path]:
    """Where a role may live, in precedence order.

    `agents/<role>/<role>.md` wins: the source tree keeps one directory per
    role so each can carry its own AGENTS.md of editing invariants. The flat
    path is kept for older layouts. The live `~/.claude/agents/` is the
    last-resort fallback — it is flat, because Claude Code scans that
    directory recursively for definitions and a stray AGENTS.md there would
    be parsed as a broken agent.
    """
    return [
        agents_dir / role / f"{role}.md",
        agents_dir / f"{role}.md",
        pathlib.Path.home() / ".claude" / "agents" / f"{role}.md",
    ]


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Return (frontmatter, body).

    Deliberately not a YAML parser: the frontmatter Claude Code accepts is
    flat `key: value` lines, and depending on PyYAML would add a runtime
    dependency to a script that runs before anything else in the lane.
    """
    if not text.startswith("---"):
        return {}, text

    lines = text.splitlines()
    end = next((i for i, ln in enumerate(lines[1:], 1) if ln.strip() == "---"), None)
    if end is None:
        return {}, text

    fm: dict[str, str] = {}
    for ln in lines[1:end]:
        key, sep, value = ln.partition(":")
        if sep and not key.startswith((" ", "\t")):
            fm[key.strip()] = value.strip()

    return fm, "\n".join(lines[end + 1 :]).lstrip("\n")


def load(agents_dir: pathlib.Path, role: str) -> tuple[pathlib.Path, dict[str, str], str]:
    """Resolve a role to (path, frontmatter, body), or exit with what was tried."""
    path = next((p for p in search_paths(agents_dir, role) if p.is_file()), None)
    if path is None:
        tried = "\n".join(f"  {p}" for p in search_paths(agents_dir, role))
        sys.exit(f"agent-def: no definition for role '{role}'. Tried:\n{tried}")

    fm, body = split_frontmatter(path.read_text(encoding="utf-8"))
    if not body.strip():
        sys.exit(f"agent-def: '{path}' has frontmatter but no body")
    return path, fm, body


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("role", nargs="?")
    ap.add_argument("--out-dir")
    ap.add_argument("--agents-dir", default=None)
    ap.add_argument(
        "--agents-json",
        default="",
        help="Comma-separated roles; print the --agents payload instead.",
    )
    ap.add_argument(
        "--drop-tools",
        default="",
        help="Comma-separated tools to remove from the declared allowlist. "
        "Used to withhold Agent from the planner while it is planning, and "
        "Write/Edit from the consultants.",
    )
    ap.add_argument("--model", default="", help="Override the frontmatter model.")
    args = ap.parse_args()

    agents_dir = pathlib.Path(
        args.agents_dir or pathlib.Path(__file__).resolve().parents[2]
    ).resolve()

    if args.agents_json:
        payload = {}
        for role in (r.strip() for r in args.agents_json.split(",") if r.strip()):
            _, fm, body = load(agents_dir, role)
            entry: dict[str, object] = {
                "description": fm.get("description", role),
                "prompt": body,
            }
            tools = [t.strip() for t in fm.get("tools", "").split(",") if t.strip()]
            if tools:
                entry["tools"] = tools
            model = MODEL_ALIASES.get(fm.get("model", ""), fm.get("model", ""))
            if model:
                entry["model"] = model
            payload[fm.get("name", role)] = entry
        json.dump(payload, sys.stdout)
        return 0

    if not args.role or not args.out_dir:
        sys.exit("agent-def: <role> and --out-dir are required without --agents-json")

    path, fm, body = load(agents_dir, args.role)

    dropped = {t.strip() for t in args.drop_tools.split(",") if t.strip()}
    declared = [t.strip() for t in fm.get("tools", "").split(",") if t.strip()]
    tools = [t for t in declared if t not in dropped]

    model = args.model or MODEL_ALIASES.get(fm.get("model", ""), fm.get("model", ""))

    out_dir = pathlib.Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    body_file = out_dir / f"{args.role}.system.md"
    body_file.write_text(body, encoding="utf-8")

    json.dump(
        {
            "role": args.role,
            "path": str(path.resolve()),
            "body_file": str(body_file),
            "tools": ",".join(tools),
            "model": model,
            "description": fm.get("description", ""),
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
