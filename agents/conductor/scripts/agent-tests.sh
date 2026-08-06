#!/usr/bin/env bash
# Test authoring — runs on a DIFFERENT engine/model than the implementer.
#
# The point of the split: a model that just wrote the code will write tests
# encoding the same misunderstanding. A different model reading only the
# diff and the acceptance criteria has to derive intent from what the code
# actually does, so it catches what the author's own tests would not.
#
# This is the one role with no `.md` definition behind it, deliberately: the
# agents/ set covers plan, implement, and review, and a test author whose
# whole value is being a different model from the implementer does not
# belong in a definition that names neither.
#
# Env: RUN_DIR SCRIPTS_DIR REPO TEST_ENGINE TEST_MODEL [PLAN_MARKDOWN]
#      [IMPL_REPORT]
set -euo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${TEST_MODEL:?}"
: "${TEST_ENGINE:=opencode}" "${PLAN_MARKDOWN:=}" "${IMPL_REPORT:=}"

WORK="$RUN_DIR/tests"
mkdir -p "$WORK"

# Tests are written against the real diff, not against what the plan claimed.
git -C "$REPO" diff > "$WORK/implementation.diff" 2>/dev/null || : > "$WORK/implementation.diff"
git -C "$REPO" diff --stat > "$WORK/diffstat.txt" 2>/dev/null || : > "$WORK/diffstat.txt"

if [ ! -s "$WORK/implementation.diff" ]; then
  echo '{"ok":false,"skipped":true,"reason":"no changes in working tree to test"}'
  exit 0
fi

{
  cat <<'HEADER'
You are writing tests for code you did NOT write. Another model implemented
it. Treat the implementation as untrusted: your job is to find where it is
wrong, not to confirm it works.

Rules:
- Derive expected behavior from the plan's acceptance criteria, NOT from
  what the implementation happens to do. Where they disagree, assert the
  criteria and let the test fail. That failure is the useful output.
- Cover edge cases the implementer plausibly skipped: empty input, boundary
  values, error paths, concurrency where relevant.
- Match the repository's existing test framework and layout. Look first.
- Do not modify implementation files. Tests only.
- Think as long as you need; there is no budget on reasoning.

HEADER
  if [ -n "$PLAN_MARKDOWN" ]; then
    echo "The plan this was built from, verbatim:"
    echo
    printf '%s\n\n' "$PLAN_MARKDOWN"
  fi
  if [ -n "$IMPL_REPORT" ]; then
    echo "What the implementation reported (claims, not evidence):"
    echo
    printf '%s\n\n' "$IMPL_REPORT"
  fi
  echo "Files changed:"
  cat "$WORK/diffstat.txt"
  echo
  echo "Implementation diff:"
  echo '```diff'
  head -c 200000 "$WORK/implementation.diff"
  echo '```'
  echo
  echo "Write the tests now, then run them and report results."
} > "$WORK/prompt.txt"

STATUS=0
ENGINE="$TEST_ENGINE" MODEL="$TEST_MODEL" \
  "$SCRIPTS_DIR/agent-run.sh" tests "$WORK/prompt.txt" "$WORK" --write || STATUS=$?

git -C "$REPO" diff --stat > "$WORK/diffstat.after.txt" 2>/dev/null || true

TEST_ENGINE="$TEST_ENGINE" TEST_MODEL="$TEST_MODEL" python3 -c '
import json, os, pathlib, sys
work, status = pathlib.Path(sys.argv[1]), int(sys.argv[2])
last = work / "last.txt"
json.dump({
    "ok": status == 0,
    "skipped": False,
    "exit_status": status,
    "engine": os.environ["TEST_ENGINE"],
    "model": os.environ["TEST_MODEL"],
    "summary": last.read_text().strip()[:6000] if last.exists() else "",
    "artifacts": str(work),
}, sys.stdout)
' "$WORK" "$STATUS"

exit 0
