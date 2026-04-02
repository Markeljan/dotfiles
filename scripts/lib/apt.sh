#!/usr/bin/env bash

apt_helper_have() {
  command -v "$1" >/dev/null 2>&1
}

apt_helper_log() {
  if declare -F log >/dev/null 2>&1; then
    log "$@"
  else
    printf '[apt-helper] %s\n' "$*"
  fi
}

apt_helper_warn() {
  if declare -F warn >/dev/null 2>&1; then
    warn "$@"
  else
    printf '[apt-helper] warning: %s\n' "$*" >&2
  fi
}

apt_helper_run_sudo() {
  if declare -F run_sudo >/dev/null 2>&1; then
    run_sudo "$@"
  else
    "$@"
  fi
}

apt_helper_download() {
  local url="$1"

  if apt_helper_have curl; then
    curl -fsSL "$url"
    return
  fi

  if apt_helper_have wget; then
    wget -qO- "$url"
    return
  fi

  return 1
}

apt_sources_include_github_cli() {
  grep -Rqs --include='*.list' --include='*.sources' 'https://cli.github.com/packages' /etc/apt 2>/dev/null
}

apt_helper_extract_github_cli_signed_by() {
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

  if ! apt_helper_have curl && ! apt_helper_have wget; then
    apt_helper_warn "GitHub CLI apt repo is configured but neither curl nor wget is available to refresh its signing key"
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
    done < <(apt_helper_extract_github_cli_signed_by "$source_file" | sort -u)
  done

  if [ "$have_signed_by" -eq 0 ]; then
    keyring_paths+=("$legacy_keyring")
  fi

  temp_keyring="$(mktemp)"
  if ! apt_helper_download "$key_url" >"$temp_keyring"; then
    rm -f "$temp_keyring"
    apt_helper_warn "failed to download the GitHub CLI apt signing key from $key_url"
    return 1
  fi

  apt_helper_log "refreshing GitHub CLI apt repository key"
  for keyring_path in "${keyring_paths[@]}"; do
    apt_helper_run_sudo mkdir -p "$(dirname "$keyring_path")"
    apt_helper_run_sudo install -m 0644 "$temp_keyring" "$keyring_path"
  done

  rm -f "$temp_keyring"
}

apt_update_with_github_cli_repair() {
  if apt_helper_run_sudo apt-get update; then
    return 0
  fi

  if repair_github_cli_apt_repo; then
    apt_helper_log "retrying apt-get update after refreshing the GitHub CLI apt repository key"
    apt_helper_run_sudo apt-get update
    return
  fi

  return 1
}
