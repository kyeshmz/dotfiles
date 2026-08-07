# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Source of truth is this repo;
`~` is the build output.

## Profiles

Not every machine wants the whole setup — some only need the Claude Code agent
definitions, and some will never have Homebrew. A machine picks one profile at
init time, and it is stored in `~/.config/chezmoi/chezmoi.toml` as `profile`.

| Profile  | What it manages | Homebrew | macOS-only scripts |
| -------- | --------------- | -------- | ------------------ |
| `claude` | `~/.claude` only — agents, skills, commands | no | no |
| `full`   | everything in this repo | yes, on macOS | yes, on macOS |

`full` on a non-macOS machine automatically drops `.Brewfile`,
`install-packages.sh`, `setup-macos.sh`, `.init-setup` and karabiner. That gate
is on `.chezmoi.os`, not on the profile, so Linux never tries to run `brew
bundle` or `xcode-select`.

### New machine — `claude` profile

No prerequisites beyond `curl`. Installs nothing but `~/.claude`, runs no
scripts, and works on macOS or Linux:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kyeshmz/dotfiles \
  --promptChoice 'Profile=claude'
```

That is the whole procedure. Nothing below applies.

### New machine — `full` profile (macOS)

`full` runs `run_once_after_install-packages.sh`, which needs Homebrew and the
App Store. Do these **first**, in this order:

1. Sign in to iCloud and the App Store — the `mas` entries in `~/.Brewfile` fail
   otherwise, and that is where Xcode comes from.
2. Install all macOS updates.
3. Quit Terminal, then grant it Full Disk Access in System Settings →
   Privacy & Security → Full Disk Access.
4. Install Homebrew:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
5. Install 1Password and sign in.

Then:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kyeshmz/dotfiles \
  --promptChoice 'Profile=full' \
  --promptString 'Email address=you@example.com'
```

Drop the `--promptString` and it asks for the git email interactively.

Expect this to take a while and to stop for input: `mise install` compiles python
and ruby from source, and both `flutter doctor --android-licenses` and
`sudo xcodebuild -license` are interactive. Restart when it finishes.

If Homebrew is missing the script exits with instructions and is **not** marked
as run, so `chezmoi apply` retries it once you have installed brew. Flutter and
Xcode steps skip with a message rather than aborting the rest.

Omit `--promptChoice` entirely and chezmoi asks, defaulting to `claude`.

### Existing machine

```sh
.bootstrap/init.sh claude            # or: full
.bootstrap/init.sh claude --dry-run  # show what would change first
```

The script installs chezmoi if it is missing, clones the repo if the source dir
is absent, regenerates the config, verifies the profile actually took effect,
prints what is now managed, and applies. Re-running it is how you switch
profiles.

Switching to a narrower profile only stops chezmoi *managing* the excluded
files. It never deletes them from `~` — use `chezmoi destroy <path>` for that,
deliberately, one path at a time.

## Claude Code config

`dot_claude/` maps to `~/.claude/`:

```
dot_claude/agents/*.md                   ->  ~/.claude/agents/*.md
dot_claude/skills/<name>/SKILL.md        ->  ~/.claude/skills/<name>/SKILL.md
dot_claude/commands/*.md                 ->  ~/.claude/commands/*.md
```

Adding another skill or agent:

```sh
chezmoi add ~/.claude/skills/<name>
```

Two rules for this directory:

- **Add leaf paths only. Never `chezmoi add ~/.claude`.** That directory also
  holds `history.jsonl`, `.credentials.json`, `sessions/`, `projects/`,
  `telemetry/` and `shell-snapshots/` — churning state, some of it secret.
- **Unmanaged skills are left alone.** chezmoi only touches what it manages, so
  plugin-provided skills and the symlinked ones under `~/.agents/skills/`
  survive an apply. Renaming the source dir to `exact_skills` would change that
  and delete them; don't.

`chezmoi add` triggers this repo's `autoCommit` + `autoPush`, and autocommit
runs `git add .` across the whole source tree — so it will sweep up any
unrelated pending changes and push them. Either commit deliberately first, or
write files into the source tree directly and commit by hand.

## Layout notes

- `.chezmoiignore` is a template. Its patterns match **target** paths
  (`.claude/agents`, not `dot_claude/agents`), and script prefixes are stripped
  — `run_once_after_install-packages.sh` is matched as `install-packages.sh`.
- `.bootstrap/` is version-controlled but never deployed: chezmoi ignores source
  entries whose names begin with a dot.
- `~/.config/chezmoi/chezmoi.toml` is **generated** by `chezmoi init` from
  `.chezmoi.toml.tmpl`. It is deliberately not a managed target — if it were,
  `chezmoi apply` would overwrite it and wipe `profile`.
- `dot_asdf/` is **untracked and never deployed**, and asdf itself is gone (see
  Runtimes below). It was 2073 files / 93MB of node-16.16.0 and flutter binaries
  captured by mistake; applying it would have created a `~/.asdf` that no
  current machine has. The local copy is left on disk deliberately —
  `rm -rf dot_asdf` in the source dir when you want the space back.
- `modify_dot_zshrc` uses the `modify_` prefix: chezmoi runs it with the current
  `~/.zshrc` on stdin and uses its stdout as the new one. See Shell config below.
- `agents/` is the source tree for the Claude agent definitions, tracked but
  never deployed. `agents/sync.sh` renders it into `~/.claude` and into
  `dot_claude/`. `.chezmoiignore` stops it landing as `~/agents`.

## Leaving the old machine

Deactivate licenses / sign out before wiping: Dropbox, Gemini 2, Screenflow,
Tower, Apple TV, Music.

## What the bootstrap script does

`run_once_after_install-packages.sh`, in order: Rosetta, `brew bundle --global`,
`mise install`, `spctl`, the flutter Android licenses, and the Xcode license.

The `after_` prefix matters — it guarantees `~/.config/mise/config.toml` is on
disk before `mise install` reads it. Without it, script and file ordering
interleave by path and `mise install` could run against no config.

`run_once_` state is keyed on the script's SHA256, so **editing this file makes
it run again** on every machine that has already run it. Check with
`chezmoi state dump | grep -A2 scriptState` before changing it.

## Shell config — injected, not copied

`~/.zshrc` is **not** copied wholesale. `modify_dot_zshrc` receives the current
file on stdin and writes back the same file with one managed block spliced in:

```sh
# >>> chezmoi managed >>>
eval "$(mise activate zsh)"
export PATH="/opt/homebrew/opt/ssh-copy-id/bin:$PATH"
export PATH="$PATH:$HOME/.pub-cache/bin"
autoload -Uz compinit && compinit
[ -r "$HOME/.config/zsh/secrets.zsh" ] && . "$HOME/.config/zsh/secrets.zsh"
eval "$(starship init zsh)"
# <<< chezmoi managed <<<
```

Everything outside the markers is left byte-for-byte alone — the ~140 lines of
Android SDK paths, llvm flags, bun/pnpm/pipx blocks and aliases this machine has
accumulated. Re-running is idempotent: the old block is stripped before the new
one is written. On a machine with no `~/.zshrc` at all, stdin is empty and you
get just the block, which is a valid working shell.

Edit the block by editing `modify_dot_zshrc`. Edits made *inside* the markers in
`~/.zshrc` are overwritten on the next apply; put machine-local things outside.

**The repo stores the script, never your file.** There is no
`chezmoi add ~/.zshrc` step, so nothing machine-local — and no key sitting in
`~/.zshrc` — is ever read into the source state. That is what makes this safe in
a public repo.

## Secrets

Keys go in `~/.config/zsh/secrets.zsh`, mode 600, which `.chezmoiignore`
excludes from the source state entirely. The managed block sources it behind
`[ -r ]`, so a machine that has not set it up still gets a working shell.

```sh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
$EDITOR ~/.config/zsh/secrets.zsh
```

`dot_config/zsh/secrets.zsh.example` **is** committed and documents the expected
variables with no values. The values themselves do not sync — on a new machine
you re-fill them from your password manager. `bw` (Bitwarden) is installed and in
both Brewfiles if you later want chezmoi to template them in at apply time.

A `pre-commit` hook backstops all of this, because `autoCommit` + `autoPush` mean
a wrong `chezmoi add` commits *and* pushes before you can react. It scans added
lines for Anthropic, OpenAI, GitHub, AWS, Slack and Google key shapes, private
key blocks, and any `*_KEY/TOKEN/SECRET/PASSWORD=` with a substantial value.
Commented and empty assignments pass, so the `.example` file does not trip it.

It lives in `.bootstrap/hooks/` so it is version-controlled, and is wired up per
clone with:

```sh
git config core.hooksPath .bootstrap/hooks
```

`.bootstrap/init.sh` does that automatically. Bypass a genuine false positive
with `git commit --no-verify`.

## Runtimes

**mise, and only mise.** asdf, nvm, pyenv, chruby and ruby-install have all been
removed — from both Brewfiles, from the shell config, and from this machine. If
you find yourself reaching for one of them, add the tool to mise instead.

node, python and ruby are pinned in
`dot_config/mise/config.toml` → `~/.config/mise/config.toml`, and
`mise install` in the bootstrap script materialises exactly those versions, so
machines set up months apart don't drift.

```sh
mise use -g node@22                          # change the global pin
chezmoi add ~/.config/mise/config.toml       # capture it back into the repo
```

`idiomatic_version_file_enable_tools = ["node"]` is set, so repos with a
`.nvmrc` or `.node-version` still resolve correctly without a `mise.toml`.

Shell activation is `eval "$(mise activate zsh)"`. It is in `create_dot_zshrc`
for new machines; existing machines already have it.
