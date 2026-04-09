#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[dotfiles] %s\n' "$*"
}

warn() {
  printf '[dotfiles] warning: %s\n' "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

download() {
  if have curl; then
    curl -fsSL "$1"
  elif have wget; then
    wget -qO- "$1"
  else
    warn "curl or wget is required"
    return 1
  fi
}

ensure_local_bin() {
  mkdir -p "$HOME/.local/bin"

  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

install_chezmoi() {
  if have chezmoi; then
    return
  fi

  ensure_local_bin
  log "installing chezmoi"
  sh -c "$(download "https://get.chezmoi.io")" -- -b "$HOME/.local/bin"
}

current_login_shell() {
  if have dscl; then
    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}'
    return
  fi

  if have getent; then
    getent passwd "$USER" | cut -d: -f7
    return
  fi

  printf '%s\n' "${SHELL:-}"
}

add_shell_to_etc_shells() {
  local fish_path="$1"

  if grep -qx "$fish_path" /etc/shells 2>/dev/null; then
    return 0
  fi

  if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' "$fish_path" >> /etc/shells
    return 0
  fi

  if have sudo; then
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
    return 0
  fi

  return 1
}

set_fish_login_shell() {
  local fish_path current_shell

  fish_path="$(command -v fish || true)"
  if [ -z "$fish_path" ]; then
    warn "fish is not installed; skipping login shell update"
    return 1
  fi

  current_shell="$(current_login_shell)"
  if [ "$current_shell" = "$fish_path" ]; then
    log "fish is already the login shell"
    return 0
  fi

  if ! add_shell_to_etc_shells "$fish_path"; then
    warn "could not add $fish_path to /etc/shells automatically"
  fi

  if ! have chsh; then
    warn "chsh is not available"
    printf 'Run these commands manually:\n'
    printf '  echo "%s" | sudo tee -a /etc/shells\n' "$fish_path"
    printf '  chsh -s "%s"\n' "$fish_path"
    return 1
  fi

  if [ ! -t 0 ]; then
    warn "non-interactive session; skipping automatic login shell update"
    printf 'Run these commands manually:\n'
    printf '  echo "%s" | sudo tee -a /etc/shells\n' "$fish_path"
    printf '  chsh -s "%s"\n' "$fish_path"
    return 1
  fi

  log "setting fish as the login shell"
  if chsh -s "$fish_path"; then
    log "login shell updated to fish"
    return 0
  fi

  warn "could not set the login shell automatically"
  printf 'Run these commands manually:\n'
  printf '  echo "%s" | sudo tee -a /etc/shells\n' "$fish_path"
  printf '  chsh -s "%s"\n' "$fish_path"
  return 1
}

main() {
  ensure_local_bin
  install_chezmoi

  log "applying chezmoi source from $REPO_DIR"
  chezmoi init --apply --source="$REPO_DIR"

  set_fish_login_shell || true
}

main "$@"
