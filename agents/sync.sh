#!/usr/bin/env bash
# Install this directory's agent definitions, skills, and commands into ~/.claude.
#
# This tree is the source of truth. ~/.claude is a build output — anything there
# that is not produced by this script is either hand-written or stale.
#
#   ./sync.sh            install, then verify
#   ./sync.sh --check    verify only; non-zero exit if ~/.claude has drifted
#   ./sync.sh --dry-run  show what would change
#
# The live layout is FLAT on purpose. ~/.claude/agents is scanned recursively for
# subagent definitions, so the per-role AGENTS.md files are deliberately NOT copied:
# a markdown file without agent frontmatter there is at best ignored and at worst
# parsed as a broken agent.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"

ROLES=(planner implementer inspector security-consultant performance-consultant debug-consultant)

MODE=install
CHEZMOI=0
for arg in "$@"; do
  case "$arg" in
    --check)   MODE=check ;;
    --dry-run) MODE=dry ;;
    --chezmoi) CHEZMOI=1 ;;
    *) echo "usage: $0 [--check|--dry-run] [--chezmoi]" >&2; exit 2 ;;
  esac
done

rc=0
note() { printf '  %-9s %s\n' "$1" "$2"; }

# copy <src> <dst> — report same/update, honour the mode
copy() {
  local s="$1" d="$2" rel="${2#$DEST/}"
  if [ -f "$d" ] && cmp -s "$s" "$d"; then
    note "same" "$rel"; return
  fi
  local verb="update"; [ -f "$d" ] || verb="new"
  case "$MODE" in
    check) note "DRIFT" "$rel"; rc=1 ;;
    dry)   note "$verb" "$rel" ;;
    install)
      mkdir -p "$(dirname "$d")"
      cp "$s" "$d"
      note "$verb" "$rel" ;;
  esac
}

echo "source: $SRC"
echo "dest:   $DEST"
echo

echo "agents/"
for r in "${ROLES[@]}"; do
  [ -f "$SRC/$r/$r.md" ] || { echo "  MISSING source: $r/$r.md" >&2; rc=1; continue; }
  copy "$SRC/$r/$r.md" "$DEST/agents/$r.md"
done

echo
echo "skills/"
for s in "$SRC"/skills/*/; do
  [ -d "$s" ] || continue
  name="$(basename "$s")"
  [ -f "$s/SKILL.md" ] || { echo "  MISSING: $name/SKILL.md" >&2; rc=1; continue; }
  copy "$s/SKILL.md" "$DEST/skills/$name/SKILL.md"
done

echo
echo "commands/"
for c in "$SRC"/commands/*.md; do
  [ -f "$c" ] || continue
  copy "$c" "$DEST/commands/$(basename "$c")"
done

# ── verify ───────────────────────────────────────────────────────────────
echo
echo "verify"

fail() { note "FAIL" "$1"; rc=1; }

# every role a caller dispatches by name must resolve
for r in "${ROLES[@]}"; do
  grep -qs "^name: $r\$" "$DEST/agents/$r.md" || fail "no 'name: $r' in agents/$r.md"
done

# no definition may declare a model — the engine is the caller's choice
if grep -rqs '^model:' "$DEST/agents/"; then
  fail "a definition declares a model: $(grep -rls '^model:' "$DEST/agents/" | tr '\n' ' ')"
fi

# routing strings must stay engine-neutral
if grep -hs '^description:' "$DEST/agents"/*.md | grep -qiE 'opus|sonnet|haiku|fable|codex|gpt|powered by'; then
  fail "a description names a model or vendor"
fi

# the live agents dir must stay flat and definition-only
if find "$DEST/agents" -name 'AGENTS.md' | grep -q .; then
  fail "AGENTS.md found under $DEST/agents — it will be parsed as a broken agent"
fi

# the skill both planner and implementer reference must exist
[ -f "$DEST/skills/handoff-contract/SKILL.md" ] || fail "handoff-contract skill missing (planner and implementer reference it by path)"

# the contract lives in the skill, not duplicated back into a definition
grep -qs 'Execute Phase <N>' "$DEST/agents/planner.md" && fail "dispatch template leaked back into planner.md"

[ $rc -eq 0 ] && note "ok" "all checks passed"

# ── capture into the chezmoi source tree ─────────────────────────────────
# Deliberately NOT `chezmoi add`. This config has git.autocommit and
# git.autopush enabled, and autocommit runs `git add .` over the whole source
# repo — so `chezmoi add` would sweep every unrelated pending change into a
# commit and push it. Writing the files into the source tree directly is the
# same outcome with no git side effects; chezmoi picks them up because the
# source dir is just a tree with `dot_` naming. Committing stays manual and
# deliberate.
if [ "$CHEZMOI" -eq 1 ] && [ $rc -eq 0 ]; then
  echo
  echo "chezmoi"
  if ! command -v chezmoi >/dev/null 2>&1; then
    note "skip" "chezmoi not on PATH"
  else
    CM_SRC="$(chezmoi source-path)"
    note "source" "$CM_SRC"
    for r in "${ROLES[@]}"; do
      copy "$DEST/agents/$r.md" "$CM_SRC/dot_claude/agents/$r.md"
    done
    for s in "$SRC"/skills/*/; do
      [ -d "$s" ] || continue
      n="$(basename "$s")"
      copy "$DEST/skills/$n/SKILL.md" "$CM_SRC/dot_claude/skills/$n/SKILL.md"
    done
    for c in "$SRC"/commands/*.md; do
      [ -f "$c" ] || continue
      copy "$DEST/commands/$(basename "$c")" "$CM_SRC/dot_claude/commands/$(basename "$c")"
    done
    if [ "$MODE" = install ]; then
      pending=$(cd "$CM_SRC" && git status --porcelain -- dot_claude | wc -l | tr -d ' ')
      note "staged" "$pending file(s) under dot_claude/ — commit them yourself"
      echo
      echo "  cd \"$CM_SRC\" && git add dot_claude && git commit -m 'Add Claude agent definitions'"
      echo "  # commit ONLY dot_claude — this repo has unrelated pending changes"
    fi
  fi
fi

echo
case "$MODE" in
  check) [ $rc -eq 0 ] && echo "in sync" || echo "OUT OF SYNC — run ./sync.sh" ;;
  dry)   echo "dry run — nothing written" ;;
  install) [ $rc -eq 0 ] && echo "synced" || echo "synced with errors" ;;
esac
exit $rc
