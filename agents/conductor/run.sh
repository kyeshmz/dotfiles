#!/usr/bin/env bash
# Entry point for all three lanes.
#
#   ./run.sh light "add rate limiting to the API" /path/to/repo
#   ./run.sh max   "refactor the auth module"     /path/to/repo
#   ./run.sh codex "port the parser to the new AST" /path/to/repo
#
# Every role in every lane is one of the `.md` definitions in ../ — the
# workflows name roles, not behaviours, so editing a definition changes what
# the lane does without touching any YAML.
#
# Creates a timestamped run directory, captures the pre-run token baseline,
# runs the workflow with --log-file (required — Conductor prints its usage
# table to the log, never to the result JSON), and prints the ledger.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$HERE/scripts"
AGENTS_DIR="$(cd "$HERE/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: run.sh <lane> <task> <repo> [options]

  lane    light | max | codex
  task    what to build (quoted)
  repo    absolute path to the target repository

Options:
  --agents-dir D       role definitions      (default ../ — this repo's agents/)
  --plan-engine E      engine for the definition-backed roles (default claude-code)
  --plan-model M       model for the definition-backed roles
  --impl-agent A       implementation role   (default implementer — the only one)
  --test-engine E      test-author engine    (default opencode; codex lane: codex)
  --test-model M       test-author model     (default parley/openai/gpt-5.6-luna)
  --code-review-model M  max lane only       (default parley/openai/gpt-5.6-terra)
  --gemini-model M     max lane only         (default gemini-3-pro)
  --no-security        skip the security consultant
  --no-perf            skip the performance consultant
  --skip-gates         auto-approve the human gate (unattended)
  --dry-run            show the execution plan and exit

Roles, all loaded from <agents-dir>/<role>.md:
  planner                  plans, then executes the plan phase by phase
  implementer              executes one phase
  inspector                correctness + plan conformance. THE GATE.
  security-consultant      exploitable vulnerabilities this diff introduced
  performance-consultant   measured regressions. Never gates.

Lanes:
  light  plan -> one cold Opus 5 review -> up to 2 planner revisions
  max    plan -> 3 independent reviews -> Opus 5 adjudicates -> 1 revision
  codex  plan -> one cold review -> the WHOLE run on the codex engine

All three then: human gate -> the planner executes the plan, dispatching
the implementation role phase by phase -> a DIFFERENT model writes the
tests -> inspector + the two consultants review -> a fresh Opus 5 checks
the result against the ORIGINAL task.

The plan engine has no fallback. Every role that matters is a definition,
and running one somewhere it has no system-prompt channel is a different
lane, not a degraded one — so preflight stops the run instead.
USAGE
}

[ $# -lt 3 ] && { usage; exit 2; }

LANE="$1"
case "$LANE" in
  light|max|codex) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "run.sh: lane must be 'light', 'max', or 'codex', got '$LANE'" >&2; exit 2 ;;
esac
TASK="$2"; REPO="$3"; shift 3

[ -d "$REPO" ] || { echo "run.sh: repo not found: $REPO" >&2; exit 2; }
REPO="$(cd "$REPO" && pwd)"

# `codex` is the friendly name; the workflow file kept its original name.
WORKFLOW="$LANE"
[ "$LANE" = "codex" ] && WORKFLOW="plan-review-implement"

PLAN_ENGINE=claude-code
PLAN_MODEL=""
TEST_ENGINE=opencode
TEST_MODEL=parley/openai/gpt-5.6-luna
IMPL_AGENT=implementer
CODE_REVIEW_MODEL=parley/openai/gpt-5.6-terra
GEMINI_MODEL=gemini-3-pro
RUN_SECURITY=true
RUN_PERF=true
EXTRA=()

# The engine is chosen for the whole run, not per role. There is one
# implementer definition and it declares no model, so whichever engine
# runs the session writes the code.
if [ "$LANE" = "codex" ]; then
  PLAN_ENGINE=codex
  PLAN_MODEL=gpt-5.6-sol
  TEST_ENGINE=codex
  TEST_MODEL=gpt-5.6-luna
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --agents-dir)        AGENTS_DIR="$2"; shift 2 ;;
    --plan-engine)       PLAN_ENGINE="$2"; shift 2 ;;
    --plan-model)        PLAN_MODEL="$2"; shift 2 ;;
    --impl-agent)        IMPL_AGENT="$2"; shift 2 ;;
    --test-engine)       TEST_ENGINE="$2"; shift 2 ;;
    --test-model)        TEST_MODEL="$2"; shift 2 ;;
    --code-review-model) CODE_REVIEW_MODEL="$2"; shift 2 ;;
    --gemini-model)      GEMINI_MODEL="$2"; shift 2 ;;
    --no-security)       RUN_SECURITY=false; shift ;;
    --no-perf)           RUN_PERF=false; shift ;;
    --skip-gates)        EXTRA+=(--skip-gates); shift ;;
    --dry-run)           EXTRA+=(--dry-run); shift ;;
    -h|--help)           usage; exit 0 ;;
    *) echo "run.sh: unknown option '$1'" >&2; exit 2 ;;
  esac
done

AGENTS_DIR="$(cd "$AGENTS_DIR" && pwd)"

# Fail here rather than three steps into a run: a missing definition means
# the role would silently degrade into a generic assistant, which is the
# exact failure the .md files exist to prevent.
MISSING=()
for role in planner "$IMPL_AGENT" inspector; do
  "$SCRIPTS_DIR/agent-def.py" "$role" --out-dir "$(mktemp -d)" \
    --agents-dir "$AGENTS_DIR" >/dev/null 2>&1 || MISSING+=("$role")
done
[ "$RUN_SECURITY" = true ] && {
  "$SCRIPTS_DIR/agent-def.py" security-consultant --out-dir "$(mktemp -d)" \
    --agents-dir "$AGENTS_DIR" >/dev/null 2>&1 || MISSING+=(security-consultant)
}
[ "$RUN_PERF" = true ] && {
  "$SCRIPTS_DIR/agent-def.py" performance-consultant --out-dir "$(mktemp -d)" \
    --agents-dir "$AGENTS_DIR" >/dev/null 2>&1 || MISSING+=(performance-consultant)
}
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "run.sh: no definition found for: ${MISSING[*]}" >&2
  echo "  looked in $AGENTS_DIR and ~/.claude/agents" >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$HERE/runs/${LANE}-${STAMP}"
mkdir -p "$RUN_DIR/tokens"

echo "── conductor: $LANE lane ──"
echo "  task    : $TASK"
echo "  repo    : $REPO"
echo "  agents  : $AGENTS_DIR"
echo "  run dir : $RUN_DIR"
echo "  roles   : $PLAN_ENGINE${PLAN_MODEL:+ @ $PLAN_MODEL}"
echo "  impl    : $IMPL_AGENT"
echo "  tests   : $TEST_ENGINE / $TEST_MODEL"
echo "  panel   : inspector$([ "$RUN_SECURITY" = true ] && echo ' + security')$([ "$RUN_PERF" = true ] && echo ' + performance')"
if [ "$LANE" = "max" ]; then
  echo "  review  : $CODE_REVIEW_MODEL"
  echo "  indep   : $GEMINI_MODEL (antigravity, else Opus 5 via claude code)"
fi
echo

"$SCRIPTS_DIR/token-report.py" --phase before --run-dir "$RUN_DIR" \
  > "$RUN_DIR/tokens/_baseline.stdout.json" 2>/dev/null || true

INPUTS=(
  -i "task=$TASK"
  -i "repo=$REPO"
  -i "agents_dir=$AGENTS_DIR"
  -i "run_dir=$RUN_DIR"
  -i "scripts_dir=$SCRIPTS_DIR"
  -i "plan_engine=$PLAN_ENGINE"
  -i "plan_model=$PLAN_MODEL"
  -i "impl_agent=$IMPL_AGENT"
  -i "test_engine=$TEST_ENGINE"
  -i "test_model=$TEST_MODEL"
  -i "run_security=$RUN_SECURITY"
  -i "run_perf=$RUN_PERF"
)
if [ "$LANE" = "max" ]; then
  INPUTS+=(-i "code_review_model=$CODE_REVIEW_MODEL" -i "gemini_model=$GEMINI_MODEL")
fi

# --log-file is REQUIRED for token accounting: display_usage_summary()
# renders the Claude-side usage table to the console/log only. It never
# reaches the result JSON, so without this the ledger sees script steps only.
LOG_FILE="$RUN_DIR/conductor.log"

set +e
conductor run "$HERE/workflows/${WORKFLOW}.yaml" \
  "${INPUTS[@]}" "${EXTRA[@]}" --log-file "$LOG_FILE"
WF_STATUS=$?
set -e

echo
"$SCRIPTS_DIR/token-report.py" --phase after --run-dir "$RUN_DIR" \
  > "$RUN_DIR/tokens/_report.stdout.json" || true

echo
echo "  artifacts : $RUN_DIR"
echo "  log       : $LOG_FILE"
echo "  ledger    : $RUN_DIR/tokens/_report.json"
exit "$WF_STATUS"
