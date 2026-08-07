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
- `create_dot_zshrc` uses the `create_` prefix: chezmoi writes `~/.zshrc` only
  when it does not exist and never touches an existing one. A long-lived machine
  accumulates additions from bun, pnpm, pipx and gcloud installers, and
  rewriting that on every apply would be destructive. Edit it for what a **new**
  machine starts with, not to push changes to old ones.
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
