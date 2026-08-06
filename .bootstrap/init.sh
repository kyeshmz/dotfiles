#!/bin/sh
# Point this machine at one of the repo's profiles, then apply.
#
#   .bootstrap/init.sh claude   only ~/.claude — agents, skills, commands
#   .bootstrap/init.sh full     everything in this repo
#
#   .bootstrap/init.sh claude --dry-run   preview only; writes nothing at all,
#                                         including ~/.config/chezmoi/chezmoi.toml
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

DRY=no
if [ $# -gt 1 ]; then
	[ "$2" = "--dry-run" ] || usage
	DRY=yes
fi

# --- chezmoi itself --------------------------------------------------------
if command -v chezmoi >/dev/null 2>&1; then
	CHEZMOI=chezmoi
elif [ -x "$HOME/.local/bin/chezmoi" ]; then
	CHEZMOI="$HOME/.local/bin/chezmoi"
elif [ "$DRY" = yes ]; then
	echo "error: chezmoi is not installed; nothing to preview" >&2
	exit 1
else
	echo "==> installing chezmoi to ~/.local/bin"
	sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
	CHEZMOI="$HOME/.local/bin/chezmoi"
fi

SRC=$($CHEZMOI source-path 2>/dev/null || true)

echo "==> profile: $PROFILE"

# --- preview path ----------------------------------------------------------
# Deliberately does NOT run `chezmoi init`: that rewrites
# ~/.config/chezmoi/chezmoi.toml, which is not a dry run by any reading.
# Render the config template to a throwaway file and read the target state
# through that instead.
if [ "$DRY" = yes ]; then
	if [ ! -d "$SRC" ]; then
		echo "error: no source dir yet — run without --dry-run to clone $REPO" >&2
		exit 1
	fi
	# chezmoi infers config format from the file extension, so the temp file has
	# to be named *.toml — hence a temp dir rather than a bare mktemp file.
	# Positional template, not -t: BSD mktemp accepts a bare prefix but GNU
	# coreutils mktemp rejects it with "too few X's in template".
	TMPD=$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-profile.XXXXXX")
	trap 'rm -rf "$TMPD"' EXIT INT TERM
	TMPCFG="$TMPD/chezmoi.toml"
	$CHEZMOI execute-template --init \
		--promptChoice "Profile=$PROFILE" \
		--promptString 'Email address=dry-run@invalid' \
		<"$SRC/.chezmoi.toml.tmpl" >"$TMPCFG"

	# Captured before printing: piping straight into sed would let a chezmoi
	# failure exit 0 and print a reassuring empty list.
	echo "==> would manage under '$PROFILE':"
	MANAGED=$($CHEZMOI --config="$TMPCFG" --no-tty managed --path-style relative)
	printf '%s\n' "$MANAGED" | sed 's/^/    /'

	echo "==> would change in \$HOME:"
	CHANGES=$($CHEZMOI --config="$TMPCFG" --no-tty apply --dry-run --verbose)
	printf '%s\n' "$CHANGES" |
		sed -n 's|^diff --git a/\([^ ]*\) b/.*|    \1|p' | sort -u

	echo "==> dry run — nothing written, real config untouched"
	exit 0
fi

# --- real path -------------------------------------------------------------
# init clones the repo when the source dir is absent, and regenerates the
# config from .chezmoi.toml.tmpl when it is present. --prompt forces
# promptChoiceOnce to ask again so an existing profile can be overridden;
# --promptChoice supplies the answer so nothing blocks on a TTY.
if [ -d "$SRC" ]; then
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

echo "==> managed under '$PROFILE':"
$CHEZMOI managed --path-style relative | sed 's/^/    /'

echo "==> applying"
$CHEZMOI apply

echo "==> done"
