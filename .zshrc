# PATH Configuration
export PATH="/opt/homebrew/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

export PATH="$PATH:$HOME/.local/bin"

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="soko"
plugins=(git bun nvm svn-fast-info fast-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# User Configuration
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='cursor'
fi

export ARCHFLAGS="-arch $(uname -m)"

# Tool Completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Aliases
alias zshconfig="cursor ~/.zshrc"
alias zshreload="source ~/.zshrc"
alias ohmyzsh="cursor ~/.oh-my-zsh"

alias pi="pnpm install"
alias prd="pnpm run dev"
alias prb="pnpm run build"
alias prs="pnpm run start"

alias bi="bun install"
alias brd="bun run dev"
alias brb="bun run build"
alias brs="bun run start"