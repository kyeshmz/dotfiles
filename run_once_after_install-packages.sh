#!/bin/sh
# Bootstrap a new macOS machine. Runs once per machine, and `after_` so that
# every dotfile — in particular ~/.config/mise/config.toml — is already in place
# before anything here reads it.
#
# A run_once script that exits non-zero is NOT recorded as run, so chezmoi
# retries it on the next apply. Steps that depend on something not installed yet
# therefore warn and skip instead of aborting everything after them.
set -eu

step() { printf '==> %s\n' "$1"; }
skip() { printf '==> SKIPPED: %s\n' "$1" >&2; }

# --- Homebrew --------------------------------------------------------------
# Hard requirement, not a skip: every other step here comes from brew. Exiting
# non-zero means chezmoi will run this script again once brew exists.
if ! command -v brew >/dev/null 2>&1; then
	cat >&2 <<'EOF'
error: Homebrew is not installed, and everything in this script depends on it.

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Then re-run `chezmoi apply` — this script has not been marked as run.
EOF
	exit 1
fi

step "rosetta"
sudo softwareupdate --install-rosetta --agree-to-license

step "brew bundle --global (~/.Brewfile)"
brew bundle --global

# Runtimes come from mise, which replaced asdf/nvm/pyenv/chruby. Versions are
# pinned in dot_config/mise/config.toml rather than resolved as `latest`, so
# machines set up months apart end up on the same node/python/ruby. Compiling
# python and ruby needs autoconf/libyaml/readline/sqlite — all listed in
# ~/.Brewfile above for exactly this reason.
step "mise install"
mise install

step "gatekeeper"
sudo spctl --master-disable

# --- interactive, and dependent on the App Store ---------------------------
if command -v flutter >/dev/null 2>&1; then
	step "flutter android licenses (interactive)"
	flutter doctor --android-licenses || skip "flutter android licenses returned non-zero"
else
	skip "flutter not on PATH — run 'flutter doctor --android-licenses' later"
fi

if [ -d /Applications/Xcode.app ]; then
	step "xcode (interactive license)"
	sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
	sudo xcodebuild -license
else
	skip "Xcode.app not present. Install it from the App Store, then:
             sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
             sudo xcodebuild -license"
fi

step "done"
