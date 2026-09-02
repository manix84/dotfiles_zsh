#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-config.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

mkdir -p "$TEST_ROOT/.oh-my-bash"
printf '%s\n' 'OMB_TEST_LOADED=true' > "$TEST_ROOT/.oh-my-bash/oh-my-bash.sh"

for file in .bashrc .bash_aliases .bash_functions .bash_inputrc .sh_aliases .sh_functions .sh_theme; do
  cp "$REPOSITORY_ROOT/$file" "$TEST_ROOT/$file"
done

HOME="$TEST_ROOT" bash --noprofile --norc -i -c '
  source "$HOME/.bashrc"
  [[ ${OMB_TEST_LOADED:-} == true ]]
  [[ $OSH_THEME == powerbash10k ]]
  [[ $DOTFILES_BASH_THEME == powerbash10k ]]
  [[ $INPUTRC == "$HOME/.bash_inputrc" ]]
  [[ " ${plugins[*]} " == *" git "* ]]
  [[ $__PB10K_TOP_LEFT == "user_info dir python ruby scm" ]]
  [[ $__PB10K_TOP_RIGHT == "exitcode cmd_duration clock" ]]
  [[ $THEME_SHOW_PYTHON == true ]]
  [[ $THEME_SHOW_RUBY == true ]]
  shopt -q histappend
  shopt -q nocaseglob
  type clear_with_gap >/dev/null 2>&1
  alias bash-reload >/dev/null 2>&1
' </dev/null

HOME="$TEST_ROOT" DOTFILES_BASH_THEME=custom-bash-theme \
  bash --noprofile --norc -i -c '
    source "$HOME/.bashrc"
    [[ $OSH_THEME == custom-bash-theme ]]
  ' </dev/null

echo "Bash configuration tests passed."
