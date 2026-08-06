#!/bin/sh
# Point this machine at one of the repo's profiles, then apply.
#
#   .bootstrap/init.sh claude   only ~/.claude — agents, skills, commands
#   .bootstrap/init.sh full     everything in this repo
#
#   .bootstrap/init.sh claude --dry-run   show what would change, write nothing
#
# Safe to re-run, and safe to run to switch an already-configured machine from
# one profile to the other. Switching to a narrower profile stops chezmoi
# managing the excluded files; it does not delete them from $HOME.
#
# This directory's name starts with a dot, so chezmoi never deploys it.
set -eu

REPO=kyeshmz/dotfiles

usage() {
	echo "usage: $0 <claude|full> [--dry-run]" >&2
	exit 2
}

PROFILE=${1:-}
case "$PROFILE" in
claude | full) ;;
*) usage ;;
esac

DRY=""
if [ $# -gt 1 ]; then
	[ "$2" = "--dry-run" ] || usage
	DRY="--dry-run --verbose"
fi

# --- chezmoi itself --------------------------------------------------------
if command -v chezmoi >/dev/null 2>&1; then
	CHEZMOI=chezmoi
elif [ -x "$HOME/.local/bin/chezmoi" ]; then
	CHEZMOI="$HOME/.local/bin/chezmoi"
else
	echo "==> installing chezmoi to ~/.local/bin"
	sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
	CHEZMOI="$HOME/.local/bin/chezmoi"
fi

# --- source tree -----------------------------------------------------------
# init clones the repo when the source dir is absent, and regenerates the
# config from .chezmoi.toml.tmpl when it is present. --prompt forces
# promptChoiceOnce to ask again so an existing profile can be overridden;
# --promptChoice supplies the answer so nothing blocks on a TTY.
echo "==> profile: $PROFILE"
if [ -d "$($CHEZMOI source-path 2>/dev/null || echo /nonexistent)" ]; then
	$CHEZMOI init --prompt --promptChoice "Profile=$PROFILE"
else
	$CHEZMOI init "$REPO" --promptChoice "Profile=$PROFILE"
fi

# --- verify the profile actually landed ------------------------------------
# The prompt flags are keyed by prompt text, so a future rename of the "Profile"
# prompt would silently leave the old value in place. Fail loudly instead.
GOT=$($CHEZMOI data | sed -n 's/.*"profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
if [ "$GOT" != "$PROFILE" ]; then
	echo "error: asked for profile '$PROFILE' but config says '${GOT:-<unset>}'" >&2
	echo "       edit ~/.config/chezmoi/chezmoi.toml, or delete it and re-run" >&2
	exit 1
fi

# --- what will be managed --------------------------------------------------
echo "==> managed under '$PROFILE':"
$CHEZMOI managed --path-style relative | sed 's/^/    /' | head -20
TOTAL=$($CHEZMOI managed | wc -l | tr -d ' ')
[ "$TOTAL" -gt 20 ] && echo "    ... $TOTAL entries total"

echo "==> applying"
# shellcheck disable=SC2086 # DRY is a deliberate word-split flag list
$CHEZMOI apply $DRY

if [ -n "$DRY" ]; then
	echo "==> dry run — nothing written"
else
	echo "==> done"
fi
