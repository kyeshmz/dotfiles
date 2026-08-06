#!/usr/bin/env bash
# The post-implementation review panel: inspector, plus the two consultants
# when the diff warrants them. Each runs from its own `.md` definition,
# loaded verbatim as the system prompt.
#
# Why one step: Conductor rejects script steps inside both `parallel:` and
# `for_each` groups, so background jobs here are the only way to get
# concurrency. That costs nothing that matters — the reviewers' independence
# comes from each getting its own process and its own prompt, not from the
# order they are launched in.
#
# Division of labour is the definitions', not this script's:
#   inspector                correctness, plan conformance, re-verification.
#                            THE GATE.
#   security-consultant      exploitable vulnerabilities this diff introduced.
#                            Its findings gate; a CLEAN verdict is not
#                            evidence the change is safe.
#   performance-consultant   measured regressions and rule artifacts.
#                            NEVER gates — its own definition forbids it from
#                            approving or rejecting.
#
# Write and Edit are withheld from the performance consultant here. It is
# allowed to write rule artifacts under .claude/rules, but those are durable
# and cost context in every future session, so they are the human's call.
# Withheld, it emits the patch text instead.
#
# Env: RUN_DIR SCRIPTS_DIR REPO AGENTS_DIR TASK PLAN_MARKDOWN
#      [PLAN_PATH] [IMPL_REPORT] [RUN_SECURITY] [RUN_PERF]
#      [ENGINE] [REVIEW_MODEL]
set -uo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${TASK:?}"
: "${AGENTS_DIR:=}" "${PLAN_MARKDOWN:=}" "${PLAN_PATH:=}" "${IMPL_REPORT:=}"
: "${RUN_SECURITY:=true}" "${RUN_PERF:=true}"
: "${ENGINE:=claude-code}" "${REVIEW_MODEL:=}"

WORK="$RUN_DIR/review"
mkdir -p "$WORK"

# The diff is what every reviewer is actually reviewing. Captured once here
# so all three see the same tree state even though they start seconds apart.
git -C "$REPO" diff > "$WORK/implementation.diff" 2>/dev/null \
  || : > "$WORK/implementation.diff"
git -C "$REPO" diff --stat > "$WORK/diffstat.txt" 2>/dev/null \
  || : > "$WORK/diffstat.txt"

# Every reviewer gets the same self-contained brief. None of them can see
# this workflow, each other, or the planner — so anything they need is here.
{
  printf 'Original task:\n%s\n\n' "$TASK"
  [ -n "$PLAN_PATH" ] && printf 'Plan path: `%s`\n\n' "$PLAN_PATH"
  printf -- '---\n\nThe plan, verbatim:\n\n%s\n\n---\n\n' "$PLAN_MARKDOWN"
  if [ -n "$IMPL_REPORT" ]; then
    printf 'What the implementation reported (claims, not evidence):\n\n%s\n\n---\n\n' \
      "$IMPL_REPORT"
  fi
  printf 'Changed files:\n\n%s\n\n' "$(cat "$WORK/diffstat.txt")"
  printf 'Read the diff in the repository yourself. Report in the format your role definition specifies.\n'
} > "$WORK/brief.txt"

# $1 role, $2 drop-tools, $3 output slot
launch() {
  local role="$1" drop="$2" slot="$3"
  local dir="$WORK/$slot"
  mkdir -p "$dir"
  cp "$WORK/brief.txt" "$dir/prompt.txt"

  local def_args=("$role" --out-dir "$dir")
  [ -n "$AGENTS_DIR" ] && def_args+=(--agents-dir "$AGENTS_DIR")
  [ -n "$drop" ] && def_args+=(--drop-tools "$drop")

  local def
  def=$("$SCRIPTS_DIR/agent-def.py" "${def_args[@]}") || {
    printf '{"ran":false,"error":"no definition for role %s"}' "$role" \
      > "$dir/result.json"
    return 0
  }

  local body tools model
  read -r body tools model <<EOF
$(DEF="$def" python3 -c '
import json, os
d = json.loads(os.environ["DEF"])
print(d["body_file"], d["tools"] or "-", d["model"] or "-")
')
EOF
  [ "$tools" = "-" ] && tools=""
  [ -n "$REVIEW_MODEL" ] && model="$REVIEW_MODEL"
  [ "$model" = "-" ] && model=""

  local status=0
  # No --write: reviewers report, others fix.
  ENGINE="$ENGINE" MODEL="$model" AGENT_DEF="$body" AGENT_TOOLS="$tools" \
    "$SCRIPTS_DIR/agent-run.sh" "review_$slot" "$dir/prompt.txt" "$dir" \
    || status=$?

  ROLE="$role" STATUS="$status" SLOT="$slot" python3 -c '
import json, os, pathlib, re, sys

d = pathlib.Path(sys.argv[1])
last = d / "last.txt"
report = last.read_text(errors="replace").strip() if last.exists() else ""

# Each definition specifies exactly one verdict token on its own line. Match
# on a line of its own so the word appearing inside prose does not count —
# but tolerate the backticks and bold markers models add around it anyway,
# because a decorated token is compliance, not drift. Order matters: the
# most severe token wins if more than one appears.
TOKENS = {
    "inspector": ("NEEDS_FIXES", "APPROVED_WITH_NITS", "APPROVED"),
    "security-consultant": ("FINDINGS", "DEGRADED", "CLEAN"),
    "performance-consultant": ("PERF_FINDINGS", "PERF_NO_TOOLING",
                               "PERF_INVESTIGATE", "PERF_CLEAN"),
}
DECOR = "[`*_ ]*"
verdict = ""
for token in TOKENS.get(os.environ["ROLE"], ()):
    if re.search("^" + DECOR + re.escape(token) + DECOR + "$", report, re.M):
        verdict = token
        break

json.dump({
    "ran": True,
    "role": os.environ["ROLE"],
    "exit_status": int(os.environ["STATUS"]),
    # An empty verdict means the reviewer did not follow its own output
    # contract. That is reported, never defaulted to a passing token.
    "verdict": verdict,
    "report": report,
}, sys.stdout)
' "$dir" > "$dir/result.json"
}

launch inspector "" inspector &
PIDS=$!

if [ "$RUN_SECURITY" = "true" ]; then
  launch security-consultant "" security &
  PIDS="$PIDS $!"
fi

if [ "$RUN_PERF" = "true" ]; then
  launch performance-consultant "Write,Edit" performance &
  PIDS="$PIDS $!"
fi

for pid in $PIDS; do wait "$pid" || true; done

python3 -c '
import json, pathlib, sys

work = pathlib.Path(sys.argv[1])

def slot(name):
    p = work / name / "result.json"
    if not p.is_file():
        return {"ran": False}
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError:
        return {"ran": False, "error": "unparseable result.json"}

inspector, security, performance = slot("inspector"), slot("security"), slot("performance")

# Gating, per the definitions themselves. The inspector is the gate. Security
# findings gate because every finding it emits already cleared its own bar.
# Performance never gates, whatever it found.
blocking = []
if inspector.get("verdict") == "NEEDS_FIXES":
    blocking.append("inspector: NEEDS_FIXES")
if inspector.get("ran") and not inspector.get("verdict"):
    blocking.append("inspector: no verdict token — treat as unreviewed")
if security.get("verdict") == "FINDINGS":
    blocking.append("security-consultant: FINDINGS")

json.dump({
    "inspector": inspector,
    "security": security,
    "performance": performance,
    "blocking": blocking,
    "gated": bool(blocking),
    # DEGRADED means the security pass could not adjudicate its own
    # candidates, not that the change is fine. Surfaced separately so it is
    # never read as a clean result.
    "security_degraded": security.get("verdict") == "DEGRADED",
    "findings_summary": " | ".join(
        k + "=" + (v.get("verdict") or "no-verdict")
        for k, v in (("inspector", inspector), ("security", security),
                     ("performance", performance))
        if v.get("ran")
    ),
}, sys.stdout)
' "$WORK"
