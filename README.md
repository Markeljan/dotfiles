# Dotfiles

Portable dotfiles for a macOS and Linux development setup with `fish` as the default shell.

This repo is intentionally narrow:

- Keep the useful baseline from the current machine.
- Skip Mac-only and host-specific helpers.
- Stay safe to install on a VPS, laptop, or fresh workstation.

## What this repo manages

- `fish` shell config
- `fisher` + `fzf.fish`
- `neovim` with Neo-tree and ToggleTerm
- `starship` prompt
- `git` defaults for machines that do not already have `~/.gitconfig`
- `tmux` baseline
- `fzf` preview helper
- A single install script that installs packages, links config, installs fish plugins, and tries to switch the default shell to `fish`

## Quick start

```bash
git clone <your-private-dotfiles-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

If the shell was not changed automatically, make sure `fish` is listed in `/etc/shells` and then run:

```bash
echo "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"
```

For a link-only install:

```bash
./install.sh --link-only
```

For package installation only:

```bash
./install.sh --packages-only
```

## Ubuntu launch script

For Ubuntu 24.04 instances, you can use
[`scripts/ubuntu-launch.sh`](scripts/ubuntu-launch.sh) as a first-boot launch
script, cloud-init user data, or other VM bootstrap flows.

It defaults to this repo and runs the full installer:

- `DOTFILES_REPO` defaults to `https://github.com/markeljan/dotfiles.git`
- `DOTFILES_REF` defaults to `main`
- `INSTALL_FLAGS` defaults to empty, which runs `./install.sh` with the full
  package and toolchain setup

The script:

- runs `apt-get update` and `apt-get upgrade`
- installs `ca-certificates`, `curl`, and `git`
- clones the dotfiles repo into `/home/ubuntu/dotfiles`
- runs `./install.sh` as the `ubuntu` user
- writes a log to `/var/log/dotfiles-launch.log`

Notes:

- The launch script will try to set `fish` as the login shell during bootstrap.
  If that step does not succeed on your instance image, run this after login:

```bash
echo "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"
```

## Included baseline

The committed `fish` setup keeps the portable parts of the current machine:

- common PATH entries for local toolchains
- `fzf` defaults and preview support
- `pnpm`, `bun`, `python`, and `git` aliases
- `eza`-based `ls` aliases when `eza` is present
- `zoxide`, `starship`, `direnv`, and `fnm` initialization when installed
- simple fish keybindings for undo/redo

The committed `neovim` setup keeps the spirit of your current config but fixes the portable parts:

- `lazy.nvim` plugin manager
- `neo-tree` sidebar on the left
- `toggleterm` terminal available on demand at the bottom
- no terminal auto-open on startup
- opens into the file editor after the tree is shown
- uses `fish` as the shell when `fish` is installed
- removes the hardcoded Python virtualenv dependency from the old config

The repo does not include:

- machine-specific SSH shortcuts
- display-management aliases
- OrbStack integration
- 1Password signing setup
- editor launch helpers tied to a specific GUI app
- the old `~/.config/nvim/env` virtualenv

## Local overrides

Keep machine-specific changes outside the repo:

- `~/.config/fish/local.fish`
- `~/.gitconfig.local`
- `~/.tmux.local.conf`

The committed configs already include hooks for those files.
Use `config/git/gitconfig.local.example` as a starting point for signing or other private git settings.

## Git behavior

If `~/.gitconfig` already exists, `install.sh` leaves it untouched. That keeps VPS-specific Git identities or host-specific signing setups intact.

If `~/.gitconfig` does not exist, the installer links in the baseline from this repo.

## Neovim behavior

This setup is intentionally simple and closer to a file browser than a traditional Vim workflow:

- the tree opens on the left at startup
- the main edit buffer stays active
- the terminal does not open by default
- `,e` toggles the tree
- `,t` or `Ctrl-\\` toggles the bottom terminal

The installer also runs `Lazy restore` headlessly so the plugins are installed during bootstrap when `nvim` is present.

## Notes

- `install.sh` supports `brew`, `apt-get`, `dnf`, and `pacman`.
- On macOS and Linux, the installer tries to add the detected `fish` binary to `/etc/shells` before it calls `chsh`.
- On Linux, if the distro `neovim` package is older than `0.8`, the installer falls back to the official stable release under `~/.local/share/neovim-stable` and symlinks `~/.local/bin/nvim`.
- When a distro package is missing, the script falls back to official installers for a few userland tools such as `starship`, `zoxide`, `fnm`, and `bun`.
- On Debian-family systems, the installer creates `~/.local/bin/fd` and `~/.local/bin/bat` symlinks when only `fdfind` or `batcat` exist.
