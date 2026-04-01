#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_ONLY=0
PACKAGES_ONLY=0
SKIP_DEFAULT_SHELL=0
SKIP_LANG_TOOLS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --link-only           Only link dotfiles into place.
  --packages-only       Only install packages and toolchains.
  --skip-default-shell  Do not try to switch the login shell to fish.
  --skip-lang-tools     Skip fnm and bun installers.
  -h, --help            Show this help text.
EOF
}

log() {
  printf '[dotfiles] %s\n' "$*"
}

warn() {
  printf '[dotfiles] warning: %s\n' "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

run_sudo() {
  if have sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

version_ge() {
  local left_major=0 left_minor=0 left_patch=0
  local right_major=0 right_minor=0 right_patch=0

  IFS=. read -r left_major left_minor left_patch <<<"$1"
  IFS=. read -r right_major right_minor right_patch <<<"$2"

  left_minor="${left_minor:-0}"
  left_patch="${left_patch:-0}"
  right_minor="${right_minor:-0}"
  right_patch="${right_patch:-0}"

  if (( left_major > right_major )); then
    return 0
  fi

  if (( left_major < right_major )); then
    return 1
  fi

  if (( left_minor > right_minor )); then
    return 0
  fi

  if (( left_minor < right_minor )); then
    return 1
  fi

  (( left_patch >= right_patch ))
}

current_nvim_version() {
  if ! have nvim; then
    return 1
  fi

  nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p'
}

install_neovim_release() {
  local archive_name archive_url extracted_dir install_dir temp_dir

  if [ "$(uname -s)" != "Linux" ]; then
    warn "automatic Neovim fallback is only supported on Linux"
    return 1
  fi

  case "$(uname -m)" in
    x86_64|amd64)
      archive_name="nvim-linux-x86_64.tar.gz"
      ;;
    aarch64|arm64)
      archive_name="nvim-linux-arm64.tar.gz"
      ;;
    *)
      warn "unsupported Linux architecture for Neovim fallback: $(uname -m)"
      return 1
      ;;
  esac

  if ! have tar; then
    warn "tar is required to install a newer Neovim release"
    return 1
  fi

  temp_dir="$(mktemp -d)"
  archive_url="https://github.com/neovim/neovim/releases/download/stable/$archive_name"
  install_dir="$HOME/.local/share/neovim-stable"
  extracted_dir="$temp_dir/${archive_name%.tar.gz}"

  log "installing Neovim stable from the official release archive"
  curl -fsSL "$archive_url" -o "$temp_dir/$archive_name"

  rm -rf "$install_dir"
  mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
  tar -xzf "$temp_dir/$archive_name" -C "$temp_dir"
  mv "$extracted_dir" "$install_dir"
  ln -sf "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
  export PATH="$HOME/.local/bin:$PATH"

  rm -rf "$temp_dir"
}

ensure_minimum_neovim() {
  local current_version

  current_version="$(current_nvim_version || true)"

  if [ -n "$current_version" ] && version_ge "$current_version" "0.8.0"; then
    return
  fi

  install_neovim_release || warn "could not install a Neovim build that satisfies the plugin requirements"
}

link_path() {
  local source_path="$1"
  local target_path="$2"
  local backup_path

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    log "already linked: $target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_path="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target_path" "$backup_path"
    log "backed up $target_path to $backup_path"
  fi

  ln -s "$source_path" "$target_path"
  log "linked $target_path"
}

link_path_if_absent() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    log "already linked: $target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    log "keeping existing $target_path"
    return
  fi

  ln -s "$source_path" "$target_path"
  log "linked $target_path"
}

detect_package_manager() {
  if have brew; then
    echo brew
  elif have apt-get; then
    echo apt
  elif have dnf; then
    echo dnf
  elif have pacman; then
    echo pacman
  else
    echo none
  fi
}

install_packages() {
  local pm
  pm="$(detect_package_manager)"

  case "$pm" in
    brew)
      local packages=(
        git
        fish
        fzf
        ripgrep
        fd
        eza
        bat
        jq
        tmux
        neovim
        python
        pipx
        zoxide
        starship
        gh
      )

      if [ "$(uname -s)" != "Darwin" ]; then
        packages=(curl unzip "${packages[@]}")
      fi

      log "installing base packages with brew"
      brew install "${packages[@]}"
      ;;
    apt)
      log "installing base packages with apt-get"
      run_sudo apt-get update
      run_sudo apt-get install -y curl git fish tmux neovim fzf ripgrep fd-find bat jq python3 python3-pip pipx unzip
      ;;
    dnf)
      log "installing base packages with dnf"
      run_sudo dnf install -y curl git fish tmux neovim fzf ripgrep fd-find bat jq python3 python3-pip pipx unzip
      ;;
    pacman)
      log "installing base packages with pacman"
      run_sudo pacman -Sy --noconfirm curl git fish tmux neovim fzf ripgrep fd bat jq python python-pip python-pipx unzip
      ;;
    none)
      warn "no supported package manager found; skipping base package installation"
      ;;
  esac
}

install_via_script_if_missing() {
  local name="$1"
  local check_cmd="$2"
  local install_cmd="$3"

  if have "$check_cmd"; then
    return
  fi

  log "installing $name"
  bash -lc "$install_cmd"
}

install_optional_toolchains() {
  local pm

  if [ "$SKIP_LANG_TOOLS" -eq 1 ]; then
    return
  fi

  pm="$(detect_package_manager)"

  install_via_script_if_missing \
    starship \
    starship \
    'curl -fsSL https://starship.rs/install.sh | sh -s -- -y'

  install_via_script_if_missing \
    zoxide \
    zoxide \
    'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'

  if ! have fnm; then
    if [ "$pm" = "brew" ]; then
      log "installing fnm with brew"
      brew install fnm
    else
      install_via_script_if_missing \
        fnm \
        fnm \
        'curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell'
    fi
  fi

  if have unzip; then
    install_via_script_if_missing \
      bun \
      bun \
      'curl -fsSL https://bun.sh/install | bash'
  else
    warn "unzip is required to install bun; skipping bun"
  fi

  if [ -x "$HOME/.local/share/fnm/fnm" ] && ! have fnm; then
    export PATH="$HOME/.local/share/fnm:$PATH"
  fi

  if have fnm; then
    eval "$(fnm env --shell bash)"

    if ! have node; then
      local current_node
      log "installing Node.js LTS with fnm"
      fnm install --lts
      current_node="$(fnm current || true)"

      if [ -n "$current_node" ] && [ "$current_node" != "system" ]; then
        fnm default "$current_node"
      fi
    fi

    if have corepack; then
      corepack enable || warn "corepack enable failed"
    fi
  fi
}

create_compat_symlinks() {
  mkdir -p "$HOME/.local/bin"

  if ! have fd && have fdfind; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log "created fd compatibility symlink"
  fi

  if ! have bat && have batcat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log "created bat compatibility symlink"
  fi
}

link_dotfiles() {
  mkdir -p "$HOME/.config/fish/conf.d" "$HOME/.config/fish/functions" "$HOME/.local/bin"

  link_path "$ROOT_DIR/config/fish/config.fish" "$HOME/.config/fish/config.fish"
  link_path "$ROOT_DIR/config/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"
  link_path "$ROOT_DIR/config/fish/conf.d/00-env.fish" "$HOME/.config/fish/conf.d/00-env.fish"
  link_path "$ROOT_DIR/config/fish/conf.d/10-fzf.fish" "$HOME/.config/fish/conf.d/10-fzf.fish"
  link_path "$ROOT_DIR/config/fish/conf.d/20-aliases.fish" "$HOME/.config/fish/conf.d/20-aliases.fish"
  link_path "$ROOT_DIR/config/fish/conf.d/30-tools.fish" "$HOME/.config/fish/conf.d/30-tools.fish"
  link_path "$ROOT_DIR/config/fish/functions/fish_user_key_bindings.fish" "$HOME/.config/fish/functions/fish_user_key_bindings.fish"
  link_path "$ROOT_DIR/config/nvim" "$HOME/.config/nvim"
  link_path "$ROOT_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
  link_path_if_absent "$ROOT_DIR/config/git/gitconfig" "$HOME/.gitconfig"
  link_path "$ROOT_DIR/config/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_path "$ROOT_DIR/bin/fzf-preview" "$HOME/.local/bin/fzf-preview"
}

install_nvim_plugins() {
  if ! have nvim; then
    warn "neovim is not installed; skipping plugin restore"
    return
  fi

  if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    warn "neovim config is not linked; skipping plugin restore"
    return
  fi

  log "installing neovim plugins"
  nvim --headless "+Lazy! restore" +qa || warn "neovim plugin restore failed"
}

install_fish_plugins() {
  if ! have fish; then
    warn "fish is not installed; skipping fisher and fish plugin setup"
    return
  fi

  if ! have curl; then
    warn "curl is not installed; skipping fisher bootstrap"
    return
  fi

  fish -lc "
    if not functions -q fisher
      curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
      fisher install jorgebucaran/fisher
    end

    if test -f ~/.config/fish/fish_plugins
      set -l plugins (string match -rv '^\s*(#|$)' < ~/.config/fish/fish_plugins)

      if test (count \$plugins) -gt 0
        fisher install \$plugins
      end
    end
  "
}

set_default_fish_shell() {
  local fish_path
  local shell_registered=1

  if [ "$SKIP_DEFAULT_SHELL" -eq 1 ]; then
    return
  fi

  if ! have fish; then
    warn "fish is not installed; cannot set it as the default shell"
    return
  fi

  fish_path="$(command -v fish)"

  if [ "${SHELL:-}" = "$fish_path" ]; then
    log "fish is already the current shell"
    return
  fi

  if [ -f /etc/shells ] && ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
    if run_sudo sh -c "printf '%s\n' '$fish_path' >> /etc/shells"; then
      log "added $fish_path to /etc/shells"
    else
      shell_registered=0
      warn "could not add $fish_path to /etc/shells; run: echo \"$fish_path\" | sudo tee -a /etc/shells"
    fi
  fi

  if [ "$shell_registered" -eq 0 ]; then
    warn "skipping chsh until $fish_path is listed in /etc/shells"
    return
  fi

  if have chsh; then
    chsh -s "$fish_path" || warn "failed to change login shell; run: chsh -s \"$fish_path\""
  else
    warn "chsh is not available; set the default shell manually to $fish_path"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --link-only)
      LINK_ONLY=1
      ;;
    --packages-only)
      PACKAGES_ONLY=1
      ;;
    --skip-default-shell)
      SKIP_DEFAULT_SHELL=1
      ;;
    --skip-lang-tools)
      SKIP_LANG_TOOLS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      warn "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "$LINK_ONLY" -eq 1 ] && [ "$PACKAGES_ONLY" -eq 1 ]; then
  warn "choose either --link-only or --packages-only, not both"
  exit 1
fi

if [ "$LINK_ONLY" -eq 0 ]; then
  install_packages
  create_compat_symlinks
  ensure_minimum_neovim
  install_optional_toolchains
fi

if [ "$PACKAGES_ONLY" -eq 0 ]; then
  link_dotfiles
  create_compat_symlinks

  if [ "$LINK_ONLY" -eq 0 ]; then
    install_fish_plugins
    install_nvim_plugins
    set_default_fish_shell
  fi
fi

log "done"
