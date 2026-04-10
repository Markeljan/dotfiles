# AGENTS.md

This repo is a minimal chezmoi-managed dotfiles baseline for macOS, Debian, and Ubuntu.

## Primary workflow

1. Bootstrap with `chezmoi init --apply Markeljan`.
2. Use `chezmoi update` for normal sync.
3. Use `chezmoi apply` when you want to re-render the current source state without pulling Git changes.

On Ubuntu, prefer `sudo snap install chezmoi --classic` and then `chezmoi init --apply Markeljan`.

If chezmoi is not installed and `snap` is unavailable, use `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Markeljan`.

Because the repo is named `dotfiles`, `chezmoi init Markeljan` uses chezmoi's default GitHub URL guessing and resolves to `Markeljan/dotfiles`.

Maintainers may also point chezmoi at an explicit local checkout with `chezmoi init --apply --source "$PWD"`.

## Managed targets

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
- `~/.config/ghostty/config` on macOS only

Top-level shell files are created when missing. `~/.ssh/config` is created by a post-apply hook when missing. If they already exist, they are preserved and may receive a small source/include hook instead of being replaced.

On macOS, `~/Library/Application Support/com.mitchellh.ghostty/config` is linked to `~/.config/ghostty/config`.

## Constraints

- Keep the repo portable across macOS, Debian, and Ubuntu.
- Do not add plugin frameworks or shell-specific bloat.
- Keep `fzf` and Neovim customizations focused on the current lightweight workflow.
- Do not store secrets in the repo.
- Keep machine-specific aliases, SSH hosts, and extra keys in local override files.
- Do not seed host aliases or existing `authorized_keys` entries from the current machine into the repo.
- Preserve any existing `~/.ssh/authorized_keys` entries when regenerating the managed file, and create `~/.ssh/authorized_keys.shared` locally when it is missing.
- Preserve existing top-level shell rc files and SSH config when a shared-file alternative is available.
- Keep `fish` as the intended login shell and do not auto-attach or repo-manage `tmux`.
- Do not reintroduce a separate installer wrapper when chezmoi can express the workflow directly.

## Verification

After changes, run:

```bash
tmp_home="$(mktemp -d)"
mkdir -p "$tmp_home/.config/nvim"
printf 'set number\n' >"$tmp_home/.config/nvim/init.vim"
HOME="$tmp_home" DOTFILES_SKIP_PACKAGES=1 DOTFILES_SKIP_LOGIN_SHELL=1 chezmoi init --apply --force --source "$PWD" --destination "$tmp_home"
bash -n "$tmp_home/.bashrc"
zsh -n "$tmp_home/.zshrc"
for file in "$tmp_home/.config/fish/config.fish" "$tmp_home"/.config/fish/conf.d/*.fish "$tmp_home"/.config/fish/functions/*.fish; do fish -n "$file"; done
HOME="$tmp_home" nvim --headless "+qa" || true
test -f "$tmp_home/.ssh/authorized_keys"
test ! -e "$tmp_home/.config/nvim/init.vim"
test ! -e "$tmp_home/.tmux.conf"
test ! -e "$tmp_home/CLAUDE.md"
rm -rf "$tmp_home"
git diff --stat
```

## Safe extension points

- `~/.config/sh/local.sh`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`

If you add new managed files, update both this document and `README.md`.
