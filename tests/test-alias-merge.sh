#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-alias-merge.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_count() {
  local expected="$1"
  local pattern="$2"
  local file="$3"
  local actual=0

  actual=$(grep -Ec "$pattern" "$file" || true)
  [[ "$actual" -eq "$expected" ]] || \
    fail "expected $expected matches for $pattern in $file; found $actual"
}

for installer in auto-install/setup.sh auto-install/setup-user.sh; do
  fixture_name=$(basename "$installer")
  fixture_home="$TEST_ROOT/$fixture_name"
  mkdir -p "$fixture_home"

  printf "%s\n" \
    "# User aliases" \
    "alias g='git -c color.ui=false'" \
    "alias user-only='printf user'" > "$fixture_home/.sh_aliases"
  printf "%s\n" \
    "# User Zsh aliases" \
    "alias history-all='fc -l -10'" > "$fixture_home/.zsh_aliases"
  printf "%s\n" \
    "# User Bash aliases" \
    "alias bash-reload='printf custom-reload'" > "$fixture_home/.bash_aliases"
  printf "%s\n" \
    "# User macOS aliases" \
    "alias o='open -a Finder'" > "$fixture_home/.osx_aliases"

  INSTALLER="$REPOSITORY_ROOT/$installer" \
  REPOSITORY_ROOT="$REPOSITORY_ROOT" \
  FIXTURE_HOME="$fixture_home" bash -c '
    export HOME="$FIXTURE_HOME"
    eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"
    DOTFILES_RAW_URL="file://$REPOSITORY_ROOT"
    INSTALL_MODE=upgrade

    download_file() {
      local source_url="" output=""
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --output=*) output="${1#--output=}" ;;
          --output) output="$2"; shift ;;
          *) source_url="$1" ;;
        esac
        shift
      done
      cp "${source_url#file://}" "$output"
    }

    install_dotfile .sh_aliases
    install_dotfile .bash_aliases
    install_dotfile .zsh_aliases
    install_dotfile .osx_aliases
  '

  assert_count 1 "^alias g=" "$fixture_home/.sh_aliases"
  assert_count 1 "^alias user-only=" "$fixture_home/.sh_aliases"
  assert_count 1 "^alias l=" "$fixture_home/.sh_aliases"
  assert_count 1 "^alias history-all=" "$fixture_home/.zsh_aliases"
  assert_count 1 "^alias cclear=" "$fixture_home/.zsh_aliases"
  assert_count 1 "^alias bash-reload=" "$fixture_home/.bash_aliases"
  assert_count 1 "^alias cclear=" "$fixture_home/.bash_aliases"
  assert_count 1 "^alias o=" "$fixture_home/.osx_aliases"
  assert_count 1 "^alias oo=" "$fixture_home/.osx_aliases"
  grep -Fqx "alias g='git -c color.ui=false'" "$fixture_home/.sh_aliases" || \
    fail "existing g alias was changed"
  grep -Fqx "alias history-all='fc -l -10'" "$fixture_home/.zsh_aliases" || \
    fail "existing history-all alias was changed"
  grep -Fqx "alias bash-reload='printf custom-reload'" "$fixture_home/.bash_aliases" || \
    fail "existing bash-reload alias was changed"
  grep -Fqx "alias o='open -a Finder'" "$fixture_home/.osx_aliases" || \
    fail "existing o alias was changed"

  cp "$fixture_home/.sh_aliases" "$fixture_home/.sh_aliases.before-second-run"
  cp "$fixture_home/.bash_aliases" "$fixture_home/.bash_aliases.before-second-run"
  cp "$fixture_home/.zsh_aliases" "$fixture_home/.zsh_aliases.before-second-run"
  cp "$fixture_home/.osx_aliases" "$fixture_home/.osx_aliases.before-second-run"

  INSTALLER="$REPOSITORY_ROOT/$installer" \
  REPOSITORY_ROOT="$REPOSITORY_ROOT" \
  FIXTURE_HOME="$fixture_home" bash -c '
    export HOME="$FIXTURE_HOME"
    eval "$(awk '\''/# === Main Install Steps ===/{exit} !/^exec > /{print}'\'' "$INSTALLER")"
    DOTFILES_RAW_URL="file://$REPOSITORY_ROOT"
    INSTALL_MODE=upgrade
    download_file() {
      local source_url="" output=""
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --output=*) output="${1#--output=}" ;;
          --output) output="$2"; shift ;;
          *) source_url="$1" ;;
        esac
        shift
      done
      cp "${source_url#file://}" "$output"
    }
    install_dotfile .sh_aliases
    install_dotfile .bash_aliases
    install_dotfile .zsh_aliases
    install_dotfile .osx_aliases
  '

  diff -u "$fixture_home/.sh_aliases.before-second-run" "$fixture_home/.sh_aliases" || \
    fail "$installer duplicated portable aliases on its second run"
  diff -u "$fixture_home/.bash_aliases.before-second-run" "$fixture_home/.bash_aliases" || \
    fail "$installer duplicated Bash aliases on its second run"
  diff -u "$fixture_home/.zsh_aliases.before-second-run" "$fixture_home/.zsh_aliases" || \
    fail "$installer duplicated Zsh aliases on its second run"
  diff -u "$fixture_home/.osx_aliases.before-second-run" "$fixture_home/.osx_aliases" || \
    fail "$installer duplicated macOS aliases on its second run"
done

echo "Alias merge tests passed."
