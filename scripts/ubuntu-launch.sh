#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

TARGET_USER="${TARGET_USER:-ubuntu}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/markeljan/dotfiles.git}"
DOTFILES_REF="${DOTFILES_REF:-main}"
INSTALL_FLAGS="${INSTALL_FLAGS:---skip-default-shell --skip-lang-tools}"
LOG_FILE="${LOG_FILE:-/var/log/dotfiles-launch.log}"

exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  printf '[ubuntu-dotfiles] %s\n' "$*"
}

die() {
  printf '[ubuntu-dotfiles] error: %s\n' "$*" >&2
  exit 1
}

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  die "target user $TARGET_USER does not exist"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
DOTFILES_DIR="${DOTFILES_DIR:-$TARGET_HOME/dotfiles}"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  die "home directory for $TARGET_USER was not found"
fi

log "updating apt metadata"
apt-get update

log "upgrading installed packages"
apt-get upgrade -y

log "removing unneeded packages"
apt-get autoremove -y

log "installing bootstrap packages"
apt-get install -y ca-certificates curl git

if [ -d "$DOTFILES_DIR/.git" ]; then
  log "reusing existing dotfiles checkout at $DOTFILES_DIR"
else
  if [ -e "$DOTFILES_DIR" ]; then
    die "$DOTFILES_DIR exists but is not a git checkout"
  fi

  log "cloning $DOTFILES_REPO ($DOTFILES_REF) to $DOTFILES_DIR"
  runuser -u "$TARGET_USER" -- env \
    HOME="$TARGET_HOME" \
    USER="$TARGET_USER" \
    DOTFILES_REPO="$DOTFILES_REPO" \
    DOTFILES_REF="$DOTFILES_REF" \
    DOTFILES_DIR="$DOTFILES_DIR" \
    bash -lc '
      set -euo pipefail
      git clone --depth 1 --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$DOTFILES_DIR"
    '
fi

log "running dotfiles installer as $TARGET_USER"
runuser -u "$TARGET_USER" -- env \
  HOME="$TARGET_HOME" \
  USER="$TARGET_USER" \
  DOTFILES_DIR="$DOTFILES_DIR" \
  INSTALL_FLAGS="$INSTALL_FLAGS" \
  bash -lc '
    set -euo pipefail
    cd "$DOTFILES_DIR"
    # shellcheck disable=SC2086
    ./install.sh $INSTALL_FLAGS
  '

log "bootstrap complete"
log "launch log saved to $LOG_FILE"
