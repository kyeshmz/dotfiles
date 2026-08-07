#!/bin/sh
# Bootstrap a new macOS machine. Runs once per machine, and `after_` so that
# every dotfile — in particular ~/.config/mise/config.toml — is already in place
# before anything here reads it.
set -eu

sudo softwareupdate --install-rosetta --agree-to-license

brew bundle --global

flutter doctor --android-licenses

# Runtimes come from mise, which replaced asdf. Versions are pinned in
# dot_config/mise/config.toml rather than resolved as `latest`, so machines set
# up months apart end up on the same node/python/ruby.
mise install

sudo spctl --master-disable
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license
