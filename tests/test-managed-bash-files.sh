#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-managed-bash.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for installer in auto-install/setup.sh auto-install/setup-user.sh; do
  fixture_name=$(basename "$installer")
  fixture_home="$TEST_ROOT/$fixture_name"
  mkdir -p "$fixture_home"
  printf '%s\n' '# User bashrc' 'export USER_SETTING=preserved' > "$fixture_home/.bashrc"
  printf '%s\n' '# User profile' 'export PROFILE_SETTING=preserved' > "$fixture_home/.bash_profile"

  for run_number in 1 2; do
    INSTALLER="$REPOSITORY_ROOT/$installer" REPOSITORY_ROOT="$REPOSITORY_ROOT" \
    FIXTURE_HOME="$fixture_home" bash -c '
      export HOME="$FIXTURE_HOME"
      eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"
      DOTFILES_RAW_URL="file://$REPOSITORY_ROOT"
      INSTALL_MODE=upgrade
      download_file() {
        local source_url="" output=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --output=*) output="${1#--output=}" ;;
            --output) output="$2"; shift ;;
            *) source_url="$1" ;;
          esac
          shift
        done
        cp "${source_url#file://}" "$output"
      }
      install_dotfile .bashrc
      install_dotfile .bash_profile
    '

    grep -Fqx 'export USER_SETTING=preserved' "$fixture_home/.bashrc" || fail "user bashrc content changed"
    grep -Fqx 'export PROFILE_SETTING=preserved' "$fixture_home/.bash_profile" || fail "user profile content changed"
    [[ $(grep -Fc '# >>> dotfiles_zsh bashrc >>>' "$fixture_home/.bashrc") -eq 1 ]] || fail "bashrc block duplicated"
    [[ $(grep -Fc '# >>> dotfiles_zsh bash-profile >>>' "$fixture_home/.bash_profile") -eq 1 ]] || fail "profile block duplicated"

    if [[ $run_number -eq 1 ]]; then
      printf '%s\n' 'export AFTER_MANAGED_BLOCK=preserved' >> "$fixture_home/.bashrc"
      cp "$fixture_home/.bashrc" "$fixture_home/.bashrc.first-run"
      cp "$fixture_home/.bash_profile" "$fixture_home/.bash_profile.first-run"
    fi
  done

  diff -u "$fixture_home/.bashrc.first-run" "$fixture_home/.bashrc" || fail "bashrc merge is not idempotent"
  diff -u "$fixture_home/.bash_profile.first-run" "$fixture_home/.bash_profile" || fail "profile merge is not idempotent"
  grep -Fqx 'export AFTER_MANAGED_BLOCK=preserved' "$fixture_home/.bashrc" || fail "content after managed block changed"
done

echo "Managed Bash startup-file tests passed."
