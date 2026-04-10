# AGENTS.md

This repo is a minimal chezmoi-managed dotfiles baseline for macOS, Debian, and Ubuntu.

## Primary workflow

1. Clone the repo.
2. Run `./install.sh`.
3. Use `chezmoi apply` for subsequent updates.

## Managed targets

- `~/.config/sh/bash_profile`
- `~/.config/sh/bashrc`
- `~/.config/sh/zprofile`
- `~/.config/sh/zshrc`
- `~/.config/sh/shared.sh`
- `~/.config/sh/ssh-tmux.sh`
- `~/.config/fish/config.fish`
- `~/.config/fish/conf.d/*.fish`
- `~/.config/fish/functions/mkcd.fish`
- `~/.config/starship.toml`
- `~/.config/nvim`
- `~/.tmux.conf`
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
- Keep `fish` as the intended login shell and shared SSH `tmux` behavior limited to interactive SSH sessions.

## Verification

After changes, run:

```bash
bash -n install.sh
tmp_home="$(mktemp -d)"
HOME="$tmp_home" DOTFILES_SKIP_PACKAGES=1 chezmoi init --apply --force --source "$PWD" --destination "$tmp_home"
bash -n "$tmp_home/.bashrc"
zsh -n "$tmp_home/.zshrc"
for file in "$tmp_home/.config/fish/config.fish" "$tmp_home"/.config/fish/conf.d/*.fish "$tmp_home"/.config/fish/functions/*.fish; do fish -n "$file"; done
nvim --headless "+qa" || true
test -f "$tmp_home/.ssh/authorized_keys"
rm -rf "$tmp_home"
git diff --stat
```

## Safe extension points

- `~/.config/sh/local.sh`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`
- `~/.tmux.local.conf`

If you add new managed files, update both this document and `README.md`.
