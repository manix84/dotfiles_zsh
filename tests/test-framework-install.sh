#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-frameworks.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

for installer in auto-install/setup.sh auto-install/setup-user.sh; do
  fixture_name=$(basename "$installer")
  fixture_home="$TEST_ROOT/$fixture_name"
  mkdir -p "$fixture_home"

  INSTALLER="$REPOSITORY_ROOT/$installer" FIXTURE_HOME="$fixture_home" bash -c '
    export HOME="$FIXTURE_HOME"
    unset ZSH ZSH_CUSTOM OSH
    eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"
    clone_count=0
    download_count=0

    git() {
      [[ "$1" == clone ]] || return 1
      local target=""
      while [[ $# -gt 0 ]]; do
        target="$1"
        shift
      done
      mkdir -p "$target"
      case "$target" in
        "$OSH_INSTALL_DIR") printf "stub\n" > "$target/oh-my-bash.sh" ;;
        "$ZSH_INSTALL_DIR") printf "stub\n" > "$target/oh-my-zsh.sh" ;;
        */powerlevel10k) printf "stub\n" > "$target/powerlevel10k.zsh-theme" ;;
        */zsh-autosuggestions) printf "stub\n" > "$target/zsh-autosuggestions.zsh" ;;
        */zsh-syntax-highlighting) printf "stub\n" > "$target/zsh-syntax-highlighting.zsh" ;;
        *) return 1 ;;
      esac
      clone_count=$((clone_count + 1))
    }

    download_file() {
      local output=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --output=*) output="${1#--output=}" ;;
          --output) output="$2"; shift ;;
        esac
        shift
      done
      printf "stub\n" > "$output"
      download_count=$((download_count + 1))
    }

    install_oh_my_bash >/dev/null
    install_oh_my_zsh >/dev/null
    [[ $clone_count -eq 5 ]]
    [[ $download_count -eq 0 ]]

    install_oh_my_bash >/dev/null
    install_oh_my_zsh >/dev/null
    [[ $clone_count -eq 5 ]]
    [[ $download_count -eq 0 ]]

    invalid_dir="$FIXTURE_HOME/invalid-framework"
    mkdir -p "$invalid_dir"
    if install_framework_checkout Invalid "$invalid_dir" missing.sh https://example.invalid/repo.git INVALID >/dev/null 2>&1; then
      exit 1
    fi
  '
done

echo "Framework installation tests passed."
