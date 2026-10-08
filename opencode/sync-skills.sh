#!/bin/sh
# Sync skills to the sshable Linux boxes (wer, kyeshmzgmk).
#
# Neither remote runs chezmoi, so `chezmoi apply` cannot reach them. This
# script rsyncs the canonical live skill trees to both boxes, into both the
# opencode and Claude skill dirs.
#
#   opencode/sync-skills.sh                 push SKILLS to all REMOTES, verify
#   opencode/sync-skills.sh --check         verify only; exit 1 on drift
#   opencode/sync-skills.sh --dry-run       show what would change
#   opencode/sync-skills.sh <skill> [...]   push only the named skills
#
# Source of truth is the live ~/.config/opencode/skills tree, which is kept
# identical to ~/.claude/skills/<skill> and to the dot_claude/dot_config
# copies in this repo. Sourcing the single canonical copy avoids rsyncing the
# absolute symlinks ~/.claude/skills uses for other skills (they point at
# /Users/kyeshmz/... and would arrive broken on Linux).
#
# To add a skill to the sync set: install it locally under both
# ~/.config/opencode/skills and ~/.claude/skills, capture it into
# dot_claude/skills and dot_config/opencode/skills, commit, then append its
# name to SKILLS below and run this script.
set -eu

REMOTES="wer kyeshmzgmk"
SKILLS="poteto-mode"
SRC_BASE="$HOME/.config/opencode/skills"
SSH_OPTS="-o ConnectTimeout=15 -o BatchMode=yes"

MODE=push
ONLY=""
for arg in "$@"; do
  case "$arg" in
    --check) MODE=check ;;
    --dry-run) MODE=dry ;;
    -h|--help)
      sed -n '2,/^set -eu/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "usage: $0 [--check|--dry-run] [<skill> ...]" >&2; exit 2 ;;
    *) ONLY="$ONLY $arg" ;;
  esac
done
[ -n "$ONLY" ] && SKILLS="$ONLY"

rc=0
for skill in $SKILLS; do
  src="$SRC_BASE/$skill"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "MISSING source: $src/SKILL.md" >&2
    rc=1
    continue
  fi
  for remote in $REMOTES; do
    oc_dest="$remote:~/.config/opencode/skills/$skill/"
    cl_dest="$remote:~/.claude/skills/$skill/"
    case "$MODE" in
      dry)
        echo "== $skill -> $remote (dry run)"
        rsync -avzn --exclude='.DS_Store' "$src/" "$oc_dest"
        rsync -avzn --exclude='.DS_Store' "$src/" "$cl_dest"
        ;;
      check)
        drift=0
        for dest in "$oc_dest" "$cl_dest"; do
          out=$(rsync -rzn --delete --exclude='.DS_Store' \
            --out-format='%n' "$src/" "$dest" 2>&1) || {
            echo "FAIL $skill -> $dest (unreachable?)"; echo "$out"
            rc=1; drift=1; continue
          }
          if [ -n "$out" ]; then
            echo "DRIFT $skill -> $dest:"; echo "$out" | sed 's/^/  /'
            drift=1
          fi
        done
        if [ "$drift" -eq 0 ]; then
          echo "in sync: $skill -> $remote"
        else
          rc=1
        fi
        ;;
      push)
        ssh $SSH_OPTS "$remote" \
          "mkdir -p ~/.config/opencode/skills/$skill ~/.claude/skills/$skill" \
          || { echo "FAIL $skill -> $remote (ssh)" >&2; rc=1; continue; }
        rsync -avz --delete --exclude='.DS_Store' "$src/" "$oc_dest" \
          || { echo "FAIL $skill -> $oc_dest" >&2; rc=1; continue; }
        rsync -avz --delete --exclude='.DS_Store' "$src/" "$cl_dest" \
          || { echo "FAIL $skill -> $cl_dest" >&2; rc=1; continue; }
        verify=$(ssh $SSH_OPTS "$remote" \
          "set -e
           test -f ~/.config/opencode/skills/$skill/SKILL.md
           test -f ~/.claude/skills/$skill/SKILL.md
           diff -rq ~/.config/opencode/skills/$skill ~/.claude/skills/$skill
           find ~/.config/opencode/skills/$skill -type f | wc -l") \
          || { echo "FAIL $skill -> $remote (verify)" >&2; rc=1; continue; }
        echo "synced: $skill -> $remote ($verify files)"
        ;;
    esac
  done
done

case "$MODE" in
  check) [ $rc -eq 0 ] && echo "all in sync" || echo "OUT OF SYNC — run opencode/sync-skills.sh" ;;
  dry) echo "dry run — nothing written" ;;
esac
exit $rc
