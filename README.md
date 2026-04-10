# Dotfiles

Minimal [chezmoi](https://www.chezmoi.io/) dotfiles for macOS, Debian, and Ubuntu.

## Quick Start

Use chezmoi directly.

If chezmoi is not installed yet on Ubuntu, prefer:

```bash
sudo snap install chezmoi --classic
chezmoi init --apply Markeljan
```

If chezmoi is not installed yet and `snap` is unavailable:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Markeljan
```

If chezmoi is already installed:

```bash
chezmoi init --apply Markeljan
```

Because this repo is named `dotfiles`, `chezmoi init Markeljan` uses chezmoi's default GitHub URL guessing and resolves to the `Markeljan/dotfiles` repo.

If `fish` does not become the login shell automatically, run:

```bash
echo "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"
```

Skip package installation when testing:

```bash
DOTFILES_SKIP_PACKAGES=1 chezmoi init --apply Markeljan
```

Skip the login-shell change when testing:

```bash
DOTFILES_SKIP_LOGIN_SHELL=1 chezmoi apply
```

## New VPS Example

On a fresh Ubuntu or Debian VPS, use a non-root user:

```bash
ssh your-user@your-server
sudo snap install chezmoi --classic
chezmoi init --apply Markeljan
```

What happens:

- chezmoi clones the repo into its source directory
- the package script installs the baseline packages with APT, Homebrew, `fnm`, Node.js LTS, `uv`, and `bun`
- your shell, SSH, Neovim, and prompt config are applied
- dotfiles tries to set `fish` as the login shell

If the shell switch cannot happen automatically, run the two manual commands shown above.

## Daily Use

Pull new repo changes and apply them:

```bash
chezmoi update
```

Preview local changes before applying:

```bash
chezmoi diff
```

Apply the current source state again:

```bash
chezmoi apply
```

Show non-script drift:

```bash
chezmoi status --exclude=scripts
```

## Updating This Repo

If you want to change the shared dotfiles source itself, work in the chezmoi source directory:

```bash
chezmoi cd
```

For example, to add a shared alias:

```bash
chezmoi cd
$EDITOR .chezmoidata/shell.toml
chezmoi diff
chezmoi apply
git add .chezmoidata/shell.toml
git commit -m "feat: add alias"
git push
```

Shared aliases live in `.chezmoidata/shell.toml`, then render into bash, zsh, and fish.

If you prefer maintaining the repo from an explicit checkout like `~/Projects/dotfiles`, point chezmoi at that checkout once:

```bash
git clone https://github.com/Markeljan/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
chezmoi init --apply --source "$PWD"
```

After that, plain `chezmoi apply`, `chezmoi update`, and `chezmoi doctor` use that checkout as the source directory.

## Syncing An Existing Local Machine

If this machine is already set up and chezmoi is already configured, the normal sync command is:

```bash
chezmoi update
```

That pulls the latest Git changes in the configured source directory and reapplies them to your home directory.

If you are actively editing the source repo on the same machine and do not want chezmoi to pull first, use:

```bash
chezmoi diff
chezmoi apply
```

## How To Change Things

Edit the files in this repo, then apply them:

```bash
chezmoi cd
$EDITOR .chezmoidata/shell.toml
chezmoi diff
chezmoi apply
```

Useful chezmoi commands:

- `chezmoi diff` shows pending home-directory changes before you apply them.
- `chezmoi apply` writes the managed files to your home directory.
- `chezmoi status --exclude=scripts` shows which managed files differ.
- `chezmoi managed` lists the files managed by chezmoi.
- `chezmoi cd` opens a shell in the source directory.
- `chezmoi update` pulls and reapplies repo changes.

## What This Repo Manages

This repo stays intentionally small:

- macOS, Debian, and Ubuntu support
- bash, zsh, and fish shell configs from one shared data model
- minimal `starship` prompt
- `fzf` preview configuration and `fzf-preview`
- shell completions for common installed tools in bash, zsh, and fish
- `tmux` installed without repo-managed auto-attach or custom config
- SSH client config with optional 1Password agent wiring
- append-safe `authorized_keys` generation from shared and local files
- minimal Neovim with a left file tree and editor pane
- package bootstrap with APT, Homebrew, `fnm`, Node.js LTS, `uv`, and `bun`
- minimal Ghostty config on macOS only

## Managed files

- `~/.config/sh/bash_profile`
- `~/.config/sh/bashrc`
- `~/.config/sh/zprofile`
- `~/.config/sh/zshrc`
- `~/.config/sh/shared.sh`
- `~/.config/fish/config.fish`
- `~/.config/fish/conf.d/*.fish`
- `~/.config/fish/functions/mkcd.fish`
- `~/.config/starship.toml`
- `~/.config/nvim`
- `~/.ssh/config.shared`
- `~/.ssh/authorized_keys`
- `~/.local/bin/fzf-preview`
- `~/.config/ghostty/config`

On macOS, chezmoi also creates a symlink from:

- `~/Library/Application Support/com.mitchellh.ghostty/config`

to:

- `~/.config/ghostty/config`

If `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`, `~/.zprofile`, or `~/.ssh/config` already exist, this repo preserves them. New machines get minimal create-only files, and existing machines get a small source/include hook when needed instead of a full replacement.

If a stale `~/.config/nvim/init.vim` exists alongside the managed `init.lua`, the cleanup hook removes `init.vim` after apply so Neovim does not see conflicting startup configs.

## Shared shell baseline

The shared shell model lives in `.chezmoidata/shell.toml`.

v1 keeps the shell layer intentionally plain, with a few restored workflow helpers:

- shared PATH entries for `~/bin`, `~/.local/bin`, and `~/.bun/bin`
- optional `brew shellenv`
- optional `fnm` initialization with Node.js LTS via `fnm`
- optional completion bootstrap for bash, zsh, fish, Bun, pnpm, cargo, and `fzf`
- optional 1Password SSH agent export via `~/.1password/agent.sock`
- optional `zoxide` and `starship` initialization
- one shared function: `mkcd`
- bun shortcuts: `b`, `bi`, `br`, `bx`
- git shortcuts: `gst`, `gfl`
- pnpm shortcuts: `pi`, `px`, `prd`, `prb`, `prs`, `prt`, `prl`, `prf`
- Claude/Codex shortcuts: `dclaude`, `dcodex`

fish uses `abbr`. bash and zsh use aliases.

`fzf` is configured with a right-hand 50% preview split and `~/.local/bin/fzf-preview`.

## SSH behavior

`~/.ssh/config.shared` is repo-managed and contains:

- generic client defaults
- optional 1Password SSH agent wiring for both `~/.1password/agent.sock` and the macOS Group Containers socket path

`~/.ssh/config` is treated as local. On machines where it already exists, dotfiles adds:

- `Include ~/.ssh/config.shared`
- `Include ~/.ssh/config.local`

On machines with no existing `~/.ssh/config`, the post-apply hook creates a minimal top-level file that also includes:

- `Include ~/.orbstack/ssh/config`
- `Include ~/.ssh/1Password/config`

`authorized_keys` is generated on every `chezmoi apply` from:

- the existing `~/.ssh/authorized_keys` file
- shared base: `~/.ssh/authorized_keys.shared` if present
- optional local append file: `~/.ssh/authorized_keys.local`

Entries are merged and de-duplicated, so existing keys are preserved rather than overwritten. If `~/.ssh/authorized_keys.shared` does not exist yet, the post-apply hook creates it as an empty local file.

When using Ghostty over SSH, the macOS Ghostty config keeps only `sudo` shell integration enabled. The shared bash, zsh, and fish startup files force `TERM=xterm-256color` for SSH sessions and also downgrade to `xterm-256color` on local hosts where `xterm-ghostty` is not resolvable.

## Packages

Package definitions live in `.chezmoidata/packages.toml`.

- macOS uses Homebrew
- Debian and Ubuntu use APT for baseline packages and Homebrew for `fnm`
- Debian and Ubuntu install the Homebrew prerequisites from the official Homebrew docs
- Bash completion support installs through `bash-completion@2` on macOS and `bash-completion` on Debian/Ubuntu
- On Debian and Ubuntu, `starship` installs from APT when available; otherwise dotfiles downloads the matching GitHub release tarball directly
- `fnm` installs through Homebrew
- Node.js LTS installs through `fnm`
- `uv` installs through the official Astral installer
- `bun` installs through the official Bun installer
- `neovim` installs through the system package manager

On macOS, the package bootstrap no longer installs Homebrew `bash` or `zsh`. The system shells are sufficient, and `fish` remains the primary shell.

Set `DOTFILES_SKIP_PACKAGES=1` when you want to test or apply the repo without running package installs.

Set `DOTFILES_SKIP_LOGIN_SHELL=1` when you want to skip the login-shell update script.

## Local overrides

Keep machine-specific changes outside the repo:

- `~/.config/sh/local.sh`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`

## Daily usage

After the first install, `chezmoi update` is the normal sync command.
