#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-config.XXXXXX")
trap 'find "$TEST_ROOT" -depth -delete' EXIT

mkdir -p "$TEST_ROOT/.oh-my-zsh"
printf '%s\n' 'ZSH_FUNCTIONS_TEST_LOADED=true' > "$TEST_ROOT/.zsh_functions"
cp "$REPOSITORY_ROOT/.zsh_aliases" "$TEST_ROOT/.zsh_aliases"
cp "$REPOSITORY_ROOT/.sh_theme" "$TEST_ROOT/.sh_theme"
printf '%s\n' \
  '[[ ${ZSH_THEME:-} == powerlevel10k/powerlevel10k ]] || return 1' \
  '[[ ${DISABLE_UPDATE_PROMPT:-} == true ]] || return 1' \
  '[[ ${DISABLE_AUTO_UPDATE:-} == false ]] || return 1' \
  '[[ ${ENABLE_CORRECTION:-} == true ]] || return 1' \
  '[[ ${COMPLETION_WAITING_DOTS:-} == true ]] || return 1' \
  '[[ ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[1]:-} == context ]] || return 1' \
  '[[ ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[-1]:-} == prompt_char ]] || return 1' \
  '[[ " ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[*]} " == *" virtualenv pyenv rbenv vcs "* ]] || return 1' \
  '[[ ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[1]:-} == status ]] || return 1' \
  '[[ ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[-1]:-} == time ]] || return 1' \
  '[[ ${#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]} == 3 ]] || return 1' \
  'OMZ_TEST_LOADED=true' > "$TEST_ROOT/.oh-my-zsh/oh-my-zsh.sh"

HOME="$TEST_ROOT" ZSH="$TEST_ROOT/.oh-my-zsh" zsh -f -c '
  source "$1/.zshrc"
  [[ ${OMZ_TEST_LOADED:-} == true ]]
  [[ $DOTFILES_ZSH_THEME == powerlevel10k/powerlevel10k ]]
  [[ " ${plugins[*]} " == *" git "* ]]
  [[ " ${plugins[*]} " == *" zsh-autosuggestions "* ]]
  [[ " ${plugins[*]} " == *" zsh-syntax-highlighting "* ]]
  [[ ${ZSH_FUNCTIONS_TEST_LOADED:-} == true ]]
  alias zsh-reload >/dev/null 2>&1
' _ "$REPOSITORY_ROOT"

HOME="$TEST_ROOT" ZSH="$TEST_ROOT/.oh-my-zsh" \
  DOTFILES_ZSH_THEME=custom-zsh-theme zsh -f -c '
    source "$1/.zshrc"
    [[ $ZSH_THEME == custom-zsh-theme ]]
  ' _ "$REPOSITORY_ROOT"

echo "Zsh configuration tests passed."
