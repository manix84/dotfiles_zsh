#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-shell-selection.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_line() {
  grep -Fqx "$1" "$2" || fail "missing $1 in $2"
}

assert_no_line() {
  if grep -Fqx "$1" "$2"; then
    fail "unexpected $1 in $2"
  fi
}

for installer in auto-install/setup.sh auto-install/setup-user.sh; do
  fixture_name=$(basename "$installer")
  fixture_root="$TEST_ROOT/$fixture_name"
  mkdir -p "$fixture_root"

  INSTALLER="$REPOSITORY_ROOT/$installer" FIXTURE_ROOT="$fixture_root" bash -c '
    export HOME="$FIXTURE_ROOT/home"
    mkdir -p "$HOME"
    eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"

    REQUESTED_SHELL=auto
    TARGET_SHELL=""
    SHELL=/bin/bash
    PLATFORM_OS=Darwin
    resolve_target_shell >/dev/null
    [[ "$TARGET_SHELL" == bash ]]

    REQUESTED_SHELL=auto
    TARGET_SHELL=""
    SHELL=/bin/fish
    PLATFORM_OS=Darwin
    resolve_target_shell >/dev/null
    [[ "$TARGET_SHELL" == zsh ]]

    REQUESTED_SHELL=auto
    TARGET_SHELL=""
    SHELL=/bin/fish
    PLATFORM_OS=Linux
    resolve_target_shell >/dev/null
    [[ "$TARGET_SHELL" == bash ]]

    printf "dotfiles_ref=main\nshell=zsh\n" > "$INSTALL_MARKER"
    REQUESTED_SHELL=auto
    TARGET_SHELL=""
    SHELL=/bin/bash
    resolve_target_shell >/dev/null
    [[ "$TARGET_SHELL" == zsh ]]

    REQUESTED_SHELL=bash
    TARGET_SHELL=""
    resolve_target_shell >/dev/null
    [[ "$TARGET_SHELL" == bash ]]

    REQUESTED_SHELL=auto
    parse_arguments --shell zsh
    [[ "$REQUESTED_SHELL" == zsh ]]
    REQUESTED_SHELL=auto
    parse_arguments --bash
    [[ "$REQUESTED_SHELL" == bash ]]
    REQUESTED_SHELL=auto
    parse_arguments --shell=bash
    [[ "$REQUESTED_SHELL" == bash ]]

    if parse_arguments --shell fish >/dev/null 2>&1; then
      exit 1
    fi

    called_framework=""
    install_oh_my_bash() { called_framework=bash; }
    install_oh_my_zsh() { called_framework=zsh; }
    TARGET_SHELL=bash
    install_shell_framework
    [[ "$called_framework" == bash ]]
    TARGET_SHELL=zsh
    install_shell_framework
    [[ "$called_framework" == zsh ]]

    TARGET_SHELL=bash
    record_install
    grep -Fqx "shell=bash" "$INSTALL_MARKER"
  '

  for target_shell in bash zsh; do
    for platform_os in Linux Darwin; do
      output_file="$fixture_root/$target_shell-$platform_os.files"
      INSTALLER="$REPOSITORY_ROOT/$installer" \
      TARGET_SHELL_TEST="$target_shell" PLATFORM_OS_TEST="$platform_os" bash -c '
        eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"
        TARGET_SHELL="$TARGET_SHELL_TEST"
        PLATFORM_OS="$PLATFORM_OS_TEST"
        install_dotfile() { printf "%s\n" "$1"; }
        install_dotfiles
      ' > "$output_file"

      assert_line .sh_theme "$output_file"
      assert_line .sh_functions "$output_file"
      assert_line .sh_aliases "$output_file"

      if [[ "$target_shell" == bash ]]; then
        assert_line .bashrc "$output_file"
        assert_line .bash_profile "$output_file"
        assert_line .bash_functions "$output_file"
        assert_line .bash_aliases "$output_file"
        assert_line .bash_inputrc "$output_file"
        assert_no_line .zshrc "$output_file"
        assert_no_line .zsh_functions "$output_file"
        assert_no_line .zsh_aliases "$output_file"
      else
        assert_line .zshrc "$output_file"
        assert_line .zsh_functions "$output_file"
        assert_line .zsh_aliases "$output_file"
        assert_no_line .bashrc "$output_file"
        assert_no_line .bash_profile "$output_file"
        assert_no_line .bash_functions "$output_file"
        assert_no_line .bash_aliases "$output_file"
        assert_no_line .bash_inputrc "$output_file"
      fi

      if [[ "$platform_os" == Darwin ]]; then
        assert_line .osx_functions "$output_file"
        assert_line .osx_aliases "$output_file"
      else
        assert_no_line .osx_functions "$output_file"
        assert_no_line .osx_aliases "$output_file"
      fi
    done
  done
done

echo "Shell selection and platform file-matrix tests passed."
