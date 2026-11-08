#!/bin/sh
# Install OpenCode plugins that are not managed via opencode.json.
#
# ~/.config/opencode/opencode.json is deliberately NOT in this repo: it
# contains live PATs and API keys, and this repo is public. Plugins therefore
# arrive via `opencode plugin add` at first apply, which appends to the
# "plugins" array in place without touching anything else.
#
# A run_once script that exits non-zero is NOT recorded as run, so chezmoi
# retries it on the next apply. Missing opencode is a warn-and-skip instead:
# not every full-profile machine has it yet, and failing here would block the
# rest of the bootstrap. Re-run `chezmoi apply --force` or install manually
# once opencode exists:
#   opencode plugin add opencode-mobile-notifications
set -eu

step() { printf '==> %s\n' "$1"; }
skip() { printf '==> SKIPPED: %s\n' "$1" >&2; }

# --- resolve the opencode binary -----------------------------------------
# `opencode` is usually on PATH, but on the Linux boxes it lives under
# ~/.opencode/desktop-ssh/<version>/opencode and is not on PATH. Check the
# usual spots before giving up.
OPENCODE=""
if command -v opencode >/dev/null 2>&1; then
	OPENCODE="$(command -v opencode)"
elif command -v opencode2 >/dev/null 2>&1; then
	OPENCODE="$(command -v opencode2)"
else
	for candidate in \
		"$HOME/.opencode/bin/opencode" \
		"$HOME/.opencode/bin/opencode2" \
		"$HOME/.local/bin/opencode"; do
		if [ -x "$candidate" ]; then
			OPENCODE="$candidate"
			break
		fi
	done
	if [ -z "$OPENCODE" ]; then
		# Last resort: the desktop-SSH managed install on Linux.
		for candidate in "$HOME"/.opencode/desktop-ssh/*/opencode; do
			if [ -x "$candidate" ]; then
				OPENCODE="$candidate"
				break
			fi
		done
	fi
fi

if [ -z "$OPENCODE" ]; then
	skip "opencode not found — install OpenCode, then run: opencode plugin add opencode-mobile-notifications"
	exit 0
fi

step "opencode binary: $OPENCODE"

CONFIG="$HOME/.config/opencode/opencode.json"
[ -f "$CONFIG" ] || CONFIG="$HOME/.config/opencode/opencode.jsonc"

install_plugin() {
	plugin="$1"
	if [ -f "$CONFIG" ] && grep -qF "\"$plugin\"" "$CONFIG" 2>/dev/null; then
		skip "$plugin already in $CONFIG"
		return 0
	fi
	step "opencode plugin add $plugin"
	"$OPENCODE" plugin add "$plugin"
}

# Phone notifications: pings the iOS app when OpenCode finishes a turn.
# Registers as plugin ID `opencode-notify-callback`. See
# https://opencode.ai/docs/build/plugins for the plugin model.
install_plugin "opencode-mobile-notifications"

step "done"
