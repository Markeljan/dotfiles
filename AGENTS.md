# AGENTS.md

This repo is a portable dotfiles baseline. Use it to install a Linux-friendly shell environment with `fish` as the primary shell.

## Primary workflow

1. Clone the repo.
2. Run `./install.sh`.
3. If package installation is not desired, run `./install.sh --link-only`.
4. If the shell was not changed automatically, run `chsh -s "$(command -v fish)"`.

## Managed targets

- `~/.config/fish/config.fish`
- `~/.config/fish/fish_plugins`
- `~/.config/fish/conf.d/*.fish`
- `~/.config/fish/functions/fish_user_key_bindings.fish`
- `~/.config/nvim`
- `~/.config/starship.toml`
- `~/.gitconfig` only when it does not already exist
- `~/.tmux.conf`
- `~/.local/bin/fzf-preview`

## Constraints

- Keep the repo portable across Linux servers and personal machines.
- Avoid Mac-only integrations unless they are behind a file existence check.
- Do not store secrets in the repo.
- Put machine-specific aliases, SSH shortcuts, and signing config in local override files instead of committed config.
- Never replace an existing `~/.gitconfig`; preserve the machine's current Git identity.
- Keep Neovim portable: no committed virtualenvs, no hardcoded per-host paths unless guarded.

## Verification

After changes, run:

```bash
bash -n install.sh
bash -n bin/fzf-preview
for file in config/fish/config.fish config/fish/conf.d/*.fish config/fish/functions/*.fish; do fish -n "$file"; done
nvim --headless "+Lazy! restore" +qa
git diff --stat
```

## Safe extension points

- `~/.config/fish/local.fish`
- `~/.gitconfig.local`
- `~/.tmux.local.conf`

If you add new managed files, update both this document and `README.md`.
