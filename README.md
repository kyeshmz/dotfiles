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

### New machine

Claude config only — no brew, no macOS scripts, works on any OS:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kyeshmz/dotfiles \
  --promptChoice 'Profile=claude'
```

Everything:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kyeshmz/dotfiles \
  --promptChoice 'Profile=full'
```

`full` also prompts for the git email. Add `--promptString 'Email address=you@example.com'`
to make it fully unattended.

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
  — `run_once_install-packages.sh` is matched as `install-packages.sh`.
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
  accumulates additions from nvm, bun, pnpm, pipx and gcloud installers, and
  rewriting that on every apply would be destructive. Edit it for what a **new**
  machine starts with, not to push changes to old ones.
- `agents/` is the source tree for the Claude agent definitions, tracked but
  never deployed. `agents/sync.sh` renders it into `~/.claude` and into
  `dot_claude/`. `.chezmoiignore` stops it landing as `~/agents`.

## Manual macOS steps (`full` profile)

Before wiping the old machine, deactivate licenses / sign out: Dropbox,
Gemini 2, Screenflow, Tower, Apple TV, Music.

On the new machine, before running the init one-liner:

1. Sign in to iCloud and the App Store — `mas` installs fail otherwise.
2. Install all macOS updates.
3. Install 1Password and sign in.
4. Quit Terminal, then grant it Full Disk Access in System Settings →
   Privacy & Security → Full Disk Access.

Afterwards, restart. `run_once_after_install-packages.sh` handles Rosetta, `brew
bundle --global`, `mise install`, the Xcode license and `spctl`. The `after_`
prefix matters: it guarantees `~/.config/mise/config.toml` is on disk before
`mise install` reads it.

## Runtimes

**mise**, not asdf. node, python and ruby are pinned in
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
