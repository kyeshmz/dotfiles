#!/usr/bin/env bash
# SUPERSEDED — see the banner in agent-fanout.sh. Implementation is now
# `agent-plan.sh MODE=implement`, which hands the phase-by-phase dispatch
# loop back to the planner definition that specifies it.
#
# Not runnable as written: it calls oc-worker.sh, which no longer exists.
#
# ── original header ──────────────────────────────────────────────────────
# Parallel implementation driver.
#
# Conductor rejects script steps in both `for_each` and `parallel:` groups,
# so the fan-out happens here instead: this one step runs the workers
# concurrently, respecting wave ordering.
#
# Waves run sequentially (a wave's dependencies must land before the next
# begins); items WITHIN a wave run in parallel up to MAX_PARALLEL.
#
# Env: RUN_DIR SCRIPTS_DIR REPO OC_MODEL QUEUE_JSON MAX_PARALLEL
set -euo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${OC_MODEL:?}" "${QUEUE_JSON:?}"
: "${MAX_PARALLEL:=4}"

WORK="$RUN_DIR/oc/workers"
mkdir -p "$WORK"
printf '%s' "$QUEUE_JSON" > "$RUN_DIR/oc/queue.json"

WAVES=$(python3 -c '
import json, os, pathlib, sys
raw = json.loads(os.environ["QUEUE_JSON"])
queue = raw.get("queue") if isinstance(raw, dict) else raw
if not queue:
    sys.exit("oc-implement: empty queue")
work = pathlib.Path(os.environ["RUN_DIR"]) / "oc" / "workers"
work.mkdir(parents=True, exist_ok=True)
waves = {}
for i, item in enumerate(queue):
    item.setdefault("id", f"task-{i}")
    waves.setdefault(int(item.get("wave", 0)), []).append(item)
for w in sorted(waves):
    with (work / f"wave-{w}.jsonl").open("w") as fh:
        for item in waves[w]:
            fh.write(json.dumps(item) + "\n")
    print(w)
')

export RUN_DIR SCRIPTS_DIR REPO OC_MODEL

for wave in $WAVES; do
  WAVE_FILE="$WORK/wave-${wave}.jsonl"
  COUNT=$(wc -l < "$WAVE_FILE" | tr -d ' ')
  echo "oc-implement: wave $wave — $COUNT item(s), up to $MAX_PARALLEL parallel" >&2

  # -I{} keeps each JSON line intact regardless of embedded spaces.
  xargs -P "$MAX_PARALLEL" -I{} -n1 "$SCRIPTS_DIR/oc-worker.sh" {} \
    < "$WAVE_FILE" || true
done

python3 -c '
import json, os, pathlib, sys
work = pathlib.Path(os.environ["RUN_DIR"]) / "oc" / "workers"
results = []
for p in sorted(work.glob("*/result.json")):
    try:
        results.append(json.loads(p.read_text()))
    except (OSError, json.JSONDecodeError):
        results.append({"task_id": p.parent.name, "ok": False,
                        "summary": "unreadable result.json"})
ok = [r for r in results if r.get("ok")]
json.dump({
    "ok": bool(results) and len(ok) == len(results),
    "total": len(results),
    "succeeded": len(ok),
    "failed": len(results) - len(ok),
    "results": results,
}, sys.stdout)
'
