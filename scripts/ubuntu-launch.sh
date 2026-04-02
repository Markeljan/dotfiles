#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

have() {
  command -v "$1" >/dev/null 2>&1
}

default_log_file() {
  if [ "$(id -u)" -eq 0 ]; then
    echo /var/log/dotfiles-launch.log
  else
    echo "${HOME:-/tmp}/dotfiles-launch.log"
  fi
}

LOG_FILE="${LOG_FILE:-$(default_log_file)}"

if ! mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || ! touch "$LOG_FILE" 2>/dev/null; then
  LOG_FILE="/tmp/dotfiles-launch.log"
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  printf '[ubuntu-dotfiles] %s\n' "$*"
}

warn() {
  printf '[ubuntu-dotfiles] warning: %s\n' "$*" >&2
}

die() {
  printf '[ubuntu-dotfiles] error: %s\n' "$*" >&2
  exit 1
}

run_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "this script needs root privileges or sudo for: $*"
  fi
}

download() {
  local url="$1"

  if have curl; then
    curl -fsSL "$url"
    return
  fi

  if have wget; then
    wget -qO- "$url"
    return
  fi

  return 1
}

apt_sources_include_github_cli() {
  grep -Rqs --include='*.list' --include='*.sources' 'https://cli.github.com/packages' /etc/apt 2>/dev/null
}

extract_github_cli_signed_by() {
  local source_file="$1"

  case "$source_file" in
    *.list)
      sed -n '/cli\.github\.com\/packages/s/.*signed-by=\([^] ]*\).*/\1/p' "$source_file"
      ;;
    *.sources)
      awk '
        /^[[:space:]]*$/ {
          if (uri_match) {
            for (i = 1; i <= signed_count; i++) {
              print signed_by[i]
            }
          }
          uri_match = 0
          signed_count = 0
          next
        }

        /^URIs:[[:space:]]*/ {
          if ($0 ~ /https:\/\/cli\.github\.com\/packages/) {
            uri_match = 1
          }
          next
        }

        /^Signed-By:[[:space:]]*/ {
          value = $0
          sub(/^[^:]*:[[:space:]]*/, "", value)
          signed_by[++signed_count] = value
        }

        END {
          if (uri_match) {
            for (i = 1; i <= signed_count; i++) {
              print signed_by[i]
            }
          }
        }
      ' "$source_file"
      ;;
  esac
}

repair_github_cli_apt_repo() {
  local source_file
  local keyring_path
  local existing_path
  local temp_keyring
  local default_keyring="/usr/share/keyrings/githubcli-archive-keyring.gpg"
  local legacy_keyring="/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg"
  local key_url="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
  local have_signed_by=0
  local -a source_files=()
  local -a keyring_paths=("$default_keyring")

  if ! apt_sources_include_github_cli; then
    return 1
  fi

  if ! have curl && ! have wget; then
    warn "GitHub CLI apt repo is configured but neither curl nor wget is available to refresh its signing key"
    return 1
  fi

  while IFS= read -r source_file; do
    [ -n "$source_file" ] || continue
    source_files+=("$source_file")
  done < <(grep -Rls --include='*.list' --include='*.sources' 'https://cli.github.com/packages' /etc/apt 2>/dev/null || true)

  for source_file in "${source_files[@]}"; do
    while IFS= read -r keyring_path; do
      [ -n "$keyring_path" ] || continue
      have_signed_by=1

      for existing_path in "${keyring_paths[@]}"; do
        if [ "$existing_path" = "$keyring_path" ]; then
          keyring_path=""
          break
        fi
      done

      [ -n "$keyring_path" ] && keyring_paths+=("$keyring_path")
    done < <(extract_github_cli_signed_by "$source_file" | sort -u)
  done

  if [ "$have_signed_by" -eq 0 ]; then
    keyring_paths+=("$legacy_keyring")
  fi

  temp_keyring="$(mktemp)"
  if ! download "$key_url" >"$temp_keyring"; then
    rm -f "$temp_keyring"
    warn "failed to download the GitHub CLI apt signing key from $key_url"
    return 1
  fi

  log "refreshing GitHub CLI apt repository key"
  for keyring_path in "${keyring_paths[@]}"; do
    run_sudo mkdir -p "$(dirname "$keyring_path")"
    run_sudo install -m 0644 "$temp_keyring" "$keyring_path"
  done

  rm -f "$temp_keyring"
}

apt_update_with_github_cli_repair() {
  if run_sudo apt-get update; then
    return 0
  fi

  if repair_github_cli_apt_repo; then
    log "retrying apt-get update after refreshing the GitHub CLI apt repository key"
    run_sudo apt-get update
    return
  fi

  return 1
}

detect_target_user() {
  if [ -n "${TARGET_USER:-}" ]; then
    echo "$TARGET_USER"
    return
  fi

  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    echo "$SUDO_USER"
    return
  fi

  if [ "$(id -u)" -ne 0 ]; then
    id -un
    return
  fi

  if id ubuntu >/dev/null 2>&1; then
    echo ubuntu
    return
  fi

  getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" && $7 !~ /(false|nologin)$/ { print $1; exit }'
}

run_as_target_user() {
  local command="$1"
  local -a env_args=(
    "HOME=$TARGET_HOME"
    "USER=$TARGET_USER"
    "LOGNAME=$TARGET_USER"
    "DOTFILES_DIR=$DOTFILES_DIR"
    "DOTFILES_REPO=$DOTFILES_REPO"
    "DOTFILES_REF=$DOTFILES_REF"
    "INSTALL_FLAGS=$INSTALL_FLAGS"
  )

  if [ "$(id -un)" = "$TARGET_USER" ] && [ "${HOME:-}" = "$TARGET_HOME" ]; then
    env "${env_args[@]}" bash -lc "$command"
    return
  fi

  if have sudo; then
    sudo -Hu "$TARGET_USER" env "${env_args[@]}" bash -lc "$command"
    return
  fi

  if [ "$(id -u)" -eq 0 ] && have runuser; then
    runuser -u "$TARGET_USER" -- env "${env_args[@]}" bash -lc "$command"
    return
  fi

  die "could not switch to target user $TARGET_USER"
}

sync_dotfiles_checkout() {
  if [ -e "$DOTFILES_DIR" ] && [ ! -d "$DOTFILES_DIR/.git" ]; then
    die "$DOTFILES_DIR exists but is not a git checkout"
  fi

  log "syncing $DOTFILES_REPO ($DOTFILES_REF) into $DOTFILES_DIR"
  run_as_target_user '
    set -euo pipefail
    mkdir -p "$DOTFILES_DIR"
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
      git init "$DOTFILES_DIR"
    fi
    cd "$DOTFILES_DIR"
    if git remote get-url origin >/dev/null 2>&1; then
      git remote set-url origin "$DOTFILES_REPO"
    else
      git remote add origin "$DOTFILES_REPO"
    fi
    git fetch --depth 1 origin "$DOTFILES_REF"
    git -c advice.detachedHead=false checkout --force FETCH_HEAD
  '
}

set_target_login_shell() {
  local fish_path
  local current_shell

  fish_path="$(run_as_target_user 'command -v fish || true')"
  if [ -z "$fish_path" ]; then
    warn "fish was not installed; leaving the login shell unchanged"
    return
  fi

  if [ -f /etc/shells ] && ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
    run_sudo sh -c "printf '%s\n' '$fish_path' >> /etc/shells"
    log "added $fish_path to /etc/shells"
  fi

  current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
  if [ "$current_shell" = "$fish_path" ]; then
    log "fish is already the login shell for $TARGET_USER"
    return
  fi

  if have usermod; then
    run_sudo usermod -s "$fish_path" "$TARGET_USER"
  elif have chsh; then
    run_sudo chsh -s "$fish_path" "$TARGET_USER"
  else
    warn "could not find usermod or chsh to update the login shell for $TARGET_USER"
    return
  fi

  log "set login shell for $TARGET_USER to $fish_path"
}

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/markeljan/dotfiles.git}"
DOTFILES_REF="${DOTFILES_REF:-main}"
INSTALL_FLAGS="${INSTALL_FLAGS:-}"
SET_LOGIN_SHELL="${SET_LOGIN_SHELL:-1}"
TARGET_USER="$(detect_target_user || true)"

if [ -z "$TARGET_USER" ]; then
  die "could not determine the target user; set TARGET_USER explicitly"
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  die "target user $TARGET_USER does not exist"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
DOTFILES_DIR="${DOTFILES_DIR:-$TARGET_HOME/dotfiles}"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  die "home directory for $TARGET_USER was not found"
fi

log "using target user $TARGET_USER"
log "launch log saved to $LOG_FILE"

log "updating apt metadata"
apt_update_with_github_cli_repair

log "upgrading installed packages"
run_sudo apt-get upgrade -y

log "removing unneeded packages"
run_sudo apt-get autoremove -y

log "installing bootstrap packages"
run_sudo apt-get install -y ca-certificates curl git sudo

sync_dotfiles_checkout

log "running dotfiles installer as $TARGET_USER"
run_as_target_user '
  set -euo pipefail
  cd "$DOTFILES_DIR"
  # shellcheck disable=SC2086
  ./install.sh --skip-default-shell $INSTALL_FLAGS
'

if [ "$SET_LOGIN_SHELL" = "1" ]; then
  set_target_login_shell
else
  log "leaving the existing login shell unchanged"
fi

log "bootstrap complete"
