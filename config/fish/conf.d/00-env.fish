function __dotfiles_add_path --argument path_entry
    if test -d "$path_entry"
        fish_add_path -gm "$path_entry"
    end
end

set -gx H $HOME

if test -d "$HOME/Projects"
    set -gx P $HOME/Projects
else if test -d "$HOME/projects"
    set -gx P $HOME/projects
end

set -gx GOPATH $HOME/go
set -gx BUN_INSTALL $HOME/.bun
set -gx FNM_DIR $HOME/.local/share/fnm
set -gx PNPM_HOME $HOME/.local/share/pnpm
set -gx CLICOLOR 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx FZF_PREVIEW_SCRIPT $HOME/.local/bin/fzf-preview

if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else
    set -gx EDITOR vi
    set -gx VISUAL vi
end

__dotfiles_add_path $HOME/.local/bin
__dotfiles_add_path $HOME/bin
__dotfiles_add_path $HOME/.cargo/bin
__dotfiles_add_path $HOME/go/bin
__dotfiles_add_path $HOME/.local/share/fnm
__dotfiles_add_path $HOME/.bun/bin
__dotfiles_add_path $HOME/.local/share/pnpm
__dotfiles_add_path $HOME/.foundry/bin

if test -d $HOME/Library/pnpm
    set -gx PNPM_HOME $HOME/Library/pnpm
    __dotfiles_add_path $HOME/Library/pnpm
end

if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

functions --erase __dotfiles_add_path
