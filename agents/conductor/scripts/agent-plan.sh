#!/usr/bin/env bash
# The planner role, in one of three modes.
#
#   plan       write the plan and stop
#   revise     rewrite the same plan against review findings
#   implement  execute the approved plan, dispatching implementers
#
# The role definition is `agents/planner.md`, loaded verbatim as the system
# prompt. Nothing in this script restates what the planner does — it only
# scopes which of the planner's own jobs this invocation is doing, and
# reports the result in a shape Conductor can route on.
#
# Why plan and implement are two invocations of one agent: the planner's
# contract has it dispatch implementers phase by phase, handling `blocked`,
# `plan-is-wrong`, resumes, and its own replan budget. Re-implementing that
# loop here would fork the seam the two .md files define between them. So
# the loop stays inside the planner, and the split exists only so the
# review panel and the human gate land BETWEEN the two halves.
#
# In `plan` and `revise` the Agent tool is withheld, which is what makes
# "plan only" a mechanism instead of a request.
#
# Env: RUN_DIR SCRIPTS_DIR REPO AGENTS_DIR MODE
#      TASK          (plan, revise)
#      PLAN_PATH     (revise, implement)
#      FINDINGS      (revise)
#      IMPL_AGENT    (implement)  role name to dispatch, default `implementer`
#      ENGINE MODEL  optional overrides; default claude-code + the model the
#                    lane supplies (definitions declare none)
set -uo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${MODE:?}"
: "${AGENTS_DIR:=}" "${TASK:=}" "${PLAN_PATH:=}" "${FINDINGS:=}"
: "${IMPL_AGENT:=implementer}" "${ENGINE:=claude-code}" "${MODEL:=}"

WORK="$RUN_DIR/planner/$MODE"
mkdir -p "$WORK"

DEF_ARGS=(planner --out-dir "$WORK")
[ -n "$AGENTS_DIR" ] && DEF_ARGS+=(--agents-dir "$AGENTS_DIR")
# Withheld while planning and revising; restored to implement.
[ "$MODE" != "implement" ] && DEF_ARGS+=(--drop-tools Agent)

DEF=$("$SCRIPTS_DIR/agent-def.py" "${DEF_ARGS[@]}") || {
  echo "agent-plan: could not resolve the planner definition" >&2
  exit 1
}

read -r AGENT_DEF AGENT_TOOLS DEF_MODEL <<EOF
$(DEF="$DEF" python3 -c '
import json, os
d = json.loads(os.environ["DEF"])
print(d["body_file"], d["tools"] or "-", d["model"] or "-")
')
EOF
[ "$AGENT_TOOLS" = "-" ] && AGENT_TOOLS=""
[ -z "$MODEL" ] && [ "$DEF_MODEL" != "-" ] && MODEL="$DEF_MODEL"
: "${MODEL:?agent-plan: no model — none in frontmatter and none passed}"

# `implement` is the only mode that dispatches, so it is the only one that
# needs the implementation role defined in-session.
SUBAGENTS_JSON=""
if [ "$MODE" = "implement" ]; then
  AJ_ARGS=(--agents-json "$IMPL_AGENT")
  [ -n "$AGENTS_DIR" ] && AJ_ARGS+=(--agents-dir "$AGENTS_DIR")
  SUBAGENTS_JSON=$("$SCRIPTS_DIR/agent-def.py" "${AJ_ARGS[@]}") || {
    echo "agent-plan: could not resolve implementation role '$IMPL_AGENT'" >&2
    exit 1
  }
fi

# Snapshot .plans/ so a plan written under a slug we cannot predict is still
# findable when the planner's PLAN: line is missing or malformed.
PLANS_BEFORE="$WORK/plans.before"
find "$REPO/.plans" -maxdepth 1 -name '*.md' -newermt '1970-01-02' 2>/dev/null \
  | sort > "$PLANS_BEFORE" || : > "$PLANS_BEFORE"
STAMP_FILE="$WORK/.stamp"
: > "$STAMP_FILE"

case "$MODE" in
  plan)
    : "${TASK:?agent-plan: TASK required in plan mode}"
    {
      printf '%s\n\n' "$TASK"
      cat <<'SCOPE'
Repository context: you are running in the repository root.

Produce the plan ONLY. Do not dispatch any implementer, and do not make
the change yourself. A review stage runs against your plan before any
implementation is authorised, and you will be invoked again to execute it
once it clears. The Agent tool is withheld from this invocation for that
reason — its absence is expected and is not a blocker.

Write the plan file exactly as your role definition specifies. Then make
the LAST line of your final message:

PLAN: <the plan path you wrote>

If you are declining because the change is too small to plan, return the
one-line instruction with no PLAN: line. If a decision belongs to the
human, return the question with no PLAN: line. Both are correct outcomes
and neither is a failure.

These instructions supersede any conflicting general instruction in your
own role definition. Do only the work described here.
SCOPE
    } > "$WORK/prompt.txt"
    ;;

  revise)
    : "${PLAN_PATH:?agent-plan: PLAN_PATH required in revise mode}"
    {
      printf 'The plan at `%s` was reviewed and did not clear the panel.\n\n' "$PLAN_PATH"
      printf 'Original task:\n%s\n\n' "$TASK"
      printf 'Reviewer findings, verbatim:\n%s\n\n' "$FINDINGS"
      cat <<'SCOPE'
Revise the plan against these findings, following your own revision rules:
overwrite the SAME path, keep every completed phase and its ticked
checkboxes exactly as written, and paste the findings into the plan's
Evidence section before you change anything.

Fix what the reviewers identified. Do not rewrite what they did not
object to — churn costs another review cycle.

Do not dispatch any implementer and do not make the change yourself. The
Agent tool is withheld from this invocation; its absence is expected.

Make the LAST line of your final message:

PLAN: <the plan path>

If a finding cannot be resolved without information you do not have, say
so explicitly under a heading `## Unresolved` before that last line, so
the human gate sees it.

These instructions supersede any conflicting general instruction in your
own role definition. Do only the work described here.
SCOPE
    } > "$WORK/prompt.txt"
    ;;

  implement)
    : "${PLAN_PATH:?agent-plan: PLAN_PATH required in implement mode}"
    {
      printf 'The plan at `%s` has been reviewed and approved. Execute it now.\n\n' "$PLAN_PATH"
      printf 'Dispatch `%s` phase by phase, starting at Phase 1.\n\n' "$IMPL_AGENT"
      cat <<'SCOPE'
Execute exactly as your role definition specifies: one dispatch per phase,
verify artifacts and exit codes between phases, honour the return contract
and the four outcome tokens, and stay inside your budgets — 2 replans per
plan, 1 re-dispatch of any single phase.

The plan's approach has already been through review. Do not redesign it.
Appending a remediation phase when an implementer returns `plan-is-wrong`
is still correct, and so is escalating when a budget is exhausted.

Make the LAST line of your final message exactly one of:

IMPLEMENTATION: complete
IMPLEMENTATION: escalated

`escalated` if you exhausted a budget, hit a halt surface, or stopped for
any reason with phases still unexecuted. Put the specific blocker and its
verbatim evidence immediately above that line.

These instructions supersede any conflicting general instruction in your
own role definition. Do only the work described here.
SCOPE
    } > "$WORK/prompt.txt"
    ;;

  *)
    echo "agent-plan: MODE must be plan, revise, or implement — got '$MODE'" >&2
    exit 2
    ;;
esac

STATUS=0
ENGINE="$ENGINE" MODEL="$MODEL" \
AGENT_DEF="$AGENT_DEF" AGENT_TOOLS="$AGENT_TOOLS" SUBAGENTS_JSON="$SUBAGENTS_JSON" \
  "$SCRIPTS_DIR/agent-run.sh" "planner_${MODE}" "$WORK/prompt.txt" "$WORK" --write \
  || STATUS=$?

REPO="$REPO" MODE="$MODE" STATUS="$STATUS" PLAN_PATH="$PLAN_PATH" python3 -c '
import json, os, pathlib, re, sys

work = pathlib.Path(sys.argv[1])
repo = pathlib.Path(os.environ["REPO"])
mode, status = os.environ["MODE"], int(os.environ["STATUS"])

last = work / "last.txt"
message = last.read_text(errors="replace").strip() if last.exists() else ""

# Backtick, double quote, single quote — spelled by codepoint because this
# whole block is a single-quoted shell string.
WRAPPERS = chr(96) + chr(34) + chr(39)


def resolve(raw):
    """A plan path from the model may be absolute, repo-relative, or fenced."""
    raw = raw.strip().strip(WRAPPERS)
    if not raw:
        return None
    p = pathlib.Path(raw)
    p = p if p.is_absolute() else repo / p
    return p if p.is_file() else None

plan = None
m = None
for m in re.finditer(r"^PLAN:\s*(.+?)\s*$", message, re.M):
    pass
if m:
    plan = resolve(m.group(1))

if plan is None and os.environ["PLAN_PATH"]:
    plan = resolve(os.environ["PLAN_PATH"])

# Last resort: the newest plan file touched during this invocation. The
# PLAN: line is a convenience, not the source of truth — the file is.
if plan is None:
    stamp = (work / ".stamp").stat().st_mtime
    touched = [p for p in sorted((repo / ".plans").glob("*.md"))
               if p.stat().st_mtime >= stamp]
    if len(touched) == 1:
        plan = touched[0]

out = {
    "mode": mode,
    "exit_status": status,
    "planner_message": message,
    "plan_path": str(plan.relative_to(repo)) if plan else "",
    "plan_markdown": plan.read_text(errors="replace") if plan else "",
}

if mode == "implement":
    tail = message.rstrip().splitlines()[-1] if message.strip() else ""
    escalated = "IMPLEMENTATION: escalated" in message
    out["ok"] = status == 0 and not escalated and "IMPLEMENTATION: complete" in message
    out["escalated"] = escalated
    # No sentinel at all means the run died or drifted; treat it as
    # escalated rather than as success, and say which it was.
    out["unterminated"] = "IMPLEMENTATION:" not in message
    out["last_line"] = tail
else:
    out["planned"] = bool(plan)
    # No plan file is a legitimate planner outcome — it declined the task
    # as too small, or it is asking the human a question. Both stop the
    # lane before implementation, and neither is an error.
    out["declined"] = not plan
    out["phase_count"] = len(re.findall(r"^##\s+Phase\s+\d+", out["plan_markdown"], re.M))

json.dump(out, sys.stdout)
' "$WORK"
