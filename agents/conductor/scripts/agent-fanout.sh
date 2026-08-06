#!/usr/bin/env bash
# SUPERSEDED — not referenced by any workflow, and not runnable as written
# (it calls oc-run.sh, which no longer exists).
#
# This was the parallel task-queue path: the planner emitted a flat array of
# independent work items and this fanned them out to concurrent workers.
# The lanes now execute `agents/planner.md`, whose contract is the opposite —
# 3-7 SEQUENTIAL phases, one implementer, each phase boundary leaving the
# tree compiling. Dependency-ordered waves have nothing to order.
#
# Kept only as a reference for the queue shape. Delete when you are sure you
# will not want it back.
#
# ── original header ──────────────────────────────────────────────────────
# Orchestrator. Takes the approved plan, resolves dependency order, and
# emits the work queue on stdout as JSON. Conductor merges parsed-JSON
# stdout keys into the step's output, so `queue` becomes
# oc_fanout.output.queue.
#
# Read-only: this step plans the execution, it must not touch the repo.
#
# Env: RUN_DIR SCRIPTS_DIR REPO OC_MODEL SHARED_CONTEXT TASKS_JSON
set -euo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${OC_MODEL:?}" "${TASKS_JSON:?}"
: "${SHARED_CONTEXT:=}"

WORK="$RUN_DIR/oc/fanout"
mkdir -p "$WORK"

python3 -c '
import json, os, sys
tasks = json.loads(os.environ["TASKS_JSON"])
if not isinstance(tasks, list) or not tasks:
    sys.exit("oc-fanout: no work items in plan")
json.dump(tasks, sys.stdout)
' > "$WORK/tasks.input.json"

{
  cat <<'HEADER'
You are the orchestrator for a parallel implementation run. You are NOT
writing any code. You are producing the execution queue that other agents
will consume.

Do this:

1. Verify no two items write the same file. If two collide, merge them into
   a single item — do not emit both.
2. Topologically order by depends_on. Assign each item a "wave" integer:
   wave 0 has no blockers, wave N depends only on waves < N.
3. For each item write a "prompt" field: the complete, standalone
   instruction the worker executes. The worker sees ONLY this string — it
   has no access to the plan, to you, or to its sibling items. Inline
   everything it needs, including the relevant shared context.
4. Preserve every item's id.

Respond with ONLY a JSON object, no prose and no code fences:

{"queue":[{"id":"...","title":"...","wave":0,"files":["..."],"prompt":"...","acceptance":"..."}]}

HEADER
  echo "Repository: $REPO"
  echo
  echo "Shared context all workers receive:"
  echo "$SHARED_CONTEXT"
  echo
  echo "Approved work items:"
  cat "$WORK/tasks.input.json"
} > "$WORK/prompt.txt"

"$SCRIPTS_DIR/oc-run.sh" oc_fanout "$OC_MODEL" "$WORK/prompt.txt" "$WORK" || {
  echo "oc-fanout: opencode run failed; see $WORK/stderr.log" >&2
  exit 1
}

python3 -c '
import json, re, sys, pathlib
raw = pathlib.Path(sys.argv[1]).read_text().strip()
raw = re.sub(r"^```(?:json)?|```$", "", raw, flags=re.M).strip()
try:
    obj = json.loads(raw)
except json.JSONDecodeError:
    m = re.search(r"\{.*\}", raw, re.S)
    if not m:
        sys.exit("oc-fanout: orchestrator returned no JSON object")
    obj = json.loads(m.group(0))
queue = obj.get("queue") if isinstance(obj, dict) else obj
if not isinstance(queue, list) or not queue:
    sys.exit("oc-fanout: empty queue")
for i, it in enumerate(queue):
    it.setdefault("id", f"task-{i}")
    it.setdefault("wave", 0)
queue.sort(key=lambda x: x.get("wave", 0))
json.dump({"queue": queue, "count": len(queue)}, sys.stdout)
' "$WORK/last.txt"
