#!/usr/bin/env bash
# SUPERSEDED — see the banner in agent-fanout.sh. The per-phase dispatch is
# now built by the planner itself, in the seven-block shape `planner.md`
# specifies, and consumed by `implementer.md`. A worker prompt assembled in
# bash from a task JSON blob cannot honour that contract.
#
# Not runnable as written: it calls oc-run.sh, which no longer exists.
#
# ── original header ──────────────────────────────────────────────────────
# One implementation worker. Invoked once per queue item by oc-implement.sh,
# up to MAX_PARALLEL concurrently. Takes the task JSON as $1.
#
# Writes its result to $RUN_DIR/oc/workers/<id>/result.json, which
# oc-implement.sh aggregates. Never exits nonzero — a failed worker must
# not abort its siblings.
#
# Env: RUN_DIR SCRIPTS_DIR REPO OC_MODEL
set -uo pipefail

TASK_JSON="${1:?oc-worker: task JSON required}"
: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${OC_MODEL:?}"

TASK_ID=$(printf '%s' "$TASK_JSON" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id","unknown"))' \
  2>/dev/null || echo unknown)
SAFE_ID=$(printf '%s' "$TASK_ID" | tr -c 'A-Za-z0-9._-' '_')
WORK="$RUN_DIR/oc/workers/$SAFE_ID"
mkdir -p "$WORK"
printf '%s' "$TASK_JSON" > "$WORK/task.json"

TASK_JSON="$TASK_JSON" python3 -c '
import json, os, sys
t = json.loads(os.environ["TASK_JSON"])
parts = [t.get("prompt") or t.get("instruction") or ""]
if t.get("files"):
    parts.append("Files in scope:\n" + "\n".join(f"  - {f}" for f in t["files"]))
if t.get("acceptance"):
    parts.append("Acceptance criteria:\n" + str(t["acceptance"]))
parts.append(
    "Implement this now. Make the edits directly in the repository.\n"
    "Do not ask questions — you are running unattended. If something is\n"
    "genuinely ambiguous, choose the most conventional option and say so\n"
    "in your final message.\n"
    "Think as long as you need; there is no budget on reasoning."
)
sys.stdout.write("\n\n".join(p for p in parts if p))
' > "$WORK/prompt.txt"

STATUS=0
"$SCRIPTS_DIR/oc-run.sh" "oc_worker_${SAFE_ID}" "$OC_MODEL" \
  "$WORK/prompt.txt" "$WORK" --write || STATUS=$?

TASK_ID="$TASK_ID" python3 -c '
import json, os, pathlib, sys
work, status = pathlib.Path(sys.argv[1]), int(sys.argv[2])
last = work / "last.txt"
json.dump({
    "task_id": os.environ["TASK_ID"],
    "ok": status == 0,
    "exit_status": status,
    "summary": last.read_text().strip()[:4000] if last.exists() else "",
    "artifacts": str(work),
}, sys.stdout)
' "$WORK" "$STATUS" > "$WORK/result.json"

exit 0
