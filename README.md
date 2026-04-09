# Dotfiles

Minimal [chezmoi](https://www.chezmoi.io/) dotfiles for macOS, Debian, and Ubuntu.

## Quick Start

This repo is the chezmoi source directory.

Install on a new machine:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Apply repo changes after editing or pulling:

```bash
cd ~/dotfiles
chezmoi diff
chezmoi apply
```

Update from Git and re-apply:

```bash
cd ~/dotfiles
git pull --ff-only
chezmoi apply
```

Skip package installation when testing:

```bash
DOTFILES_SKIP_PACKAGES=1 ./install.sh
```

## How To Change Things

Edit the files in this repo, then apply them:

```bash
cd ~/dotfiles
$EDITOR dot_zshrc.tmpl
chezmoi diff
chezmoi apply
```

Useful chezmoi commands:

- `chezmoi diff` shows pending home-directory changes before you apply them.
- `chezmoi apply` writes the managed files to your home directory.
- `chezmoi status` shows which managed files differ.
- `chezmoi managed` lists the files managed by chezmoi.

`install.sh` does three things:

1. installs `chezmoi` if it is missing
2. runs `chezmoi init --apply --source="$PWD"`
3. tries to set `fish` as the login shell

If the login shell update cannot complete automatically, the script prints the exact manual commands to run.

## What This Repo Manages

This repo stays intentionally small:

- macOS, Debian, and Ubuntu support
- bash, zsh, and fish shell configs from one shared data model
- minimal `starship` prompt
- `fzf` preview configuration and `fzf-preview`
- `tmux` baseline with SSH-only auto-attach to a persistent `main` session
- SSH client config with optional 1Password agent wiring
- append-safe `authorized_keys` generation from shared and local files
- minimal Neovim with a left file tree and editor pane
- package bootstrap with Homebrew, APT, `uv`, and `bun`
- minimal Ghostty config on macOS only

## Managed files

- `~/.bash_profile`
- `~/.bashrc`
- `~/.zprofile`
- `~/.zshrc`
- `~/.config/sh/shared.sh`
- `~/.config/sh/ssh-tmux.sh`
- `~/.config/fish/config.fish`
- `~/.config/fish/conf.d/*.fish`
- `~/.config/fish/functions/mkcd.fish`
- `~/.config/starship.toml`
- `~/.config/nvim`
- `~/.tmux.conf`
- `~/.ssh/config`
- `~/.ssh/authorized_keys.shared`
- `~/.ssh/authorized_keys`
- `~/.local/bin/fzf-preview`
- `~/.config/ghostty/config`

On macOS, chezmoi also creates a symlink from:

- `~/Library/Application Support/com.mitchellh.ghostty/config`

to:

- `~/.config/ghostty/config`

## Shared shell baseline

The shared shell model lives in `.chezmoidata/shell.toml`.

v1 keeps the shell layer intentionally plain, with a few restored workflow helpers:

- shared PATH entries for `~/.local/bin` and `~/.bun/bin`
- optional `brew shellenv`
- optional 1Password SSH agent export via `~/.1password/agent.sock`
- optional `zoxide` and `starship` initialization
- one shared function: `mkcd`
- bun shortcuts: `b`, `bi`, `br`, `bx`
- git shortcuts: `gst`, `gfl`
- pnpm shortcuts: `pi`, `px`, `prd`, `prb`, `prs`, `prt`, `prl`, `prf`
- Claude/Codex shortcuts: `dclaude`, `dcodex`

fish uses `abbr`. bash and zsh use aliases.

`fzf` is configured with a right-hand 50% preview split and `~/.local/bin/fzf-preview`.

## SSH and tmux behavior

`~/.ssh/config` is repo-managed and includes:

- generic client defaults
- `~/.ssh/config.local` when present
- `~/.ssh/1Password/config` when present

`IdentityAgent ~/.1password/agent.sock` is enabled only when the socket exists.

`authorized_keys` is generated on every `chezmoi apply` from:

- the existing `~/.ssh/authorized_keys` file
- shared base: `~/.ssh/authorized_keys.shared`
- optional local append file: `~/.ssh/authorized_keys.local`

Entries are merged and de-duplicated, so existing keys are preserved rather than overwritten.

Interactive SSH logins auto-attach to a shared `tmux` session named `main` when:

- the shell is interactive
- `SSH_CONNECTION` is set
- `TMUX` is not already set
- `SSH_ORIGINAL_COMMAND` is not set

Disconnecting the SSH client detaches from `tmux`; it does not kill the session.

## Packages

Package definitions live in `.chezmoidata/packages.toml`.

- macOS uses Homebrew
- Debian and Ubuntu use APT
- `uv` installs through the official Astral installer
- `bun` installs through the official Bun installer
- `neovim` installs through the system package manager

Set `DOTFILES_SKIP_PACKAGES=1` when you want to test or apply the repo without running package installs.

## Local overrides

Keep machine-specific changes outside the repo:

- `~/.config/sh/local.sh`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`
- `~/.tmux.local.conf`

## Daily usage

After the first install:

```bash
chezmoi apply
```

If this repo is your chezmoi source directory and you pull new changes into it:

```bash
git pull --ff-only
chezmoi apply
```
