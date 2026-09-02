#!/bin/bash

set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
for shell_name in bash zsh; do
  "$shell_name" -c '
    source "$1/.sh_functions"
    for function_name in mkd fs diff cdl dataurl gz httpcompression json digga escape unidecode codepoint grok killport sshwait; do
      "$function_name" --help >/dev/null || exit 1
      "$function_name" -h >/dev/null || exit 1
    done

    for function_name in note remind server phpserver unquarantine mount_ssh; do
      if typeset -f "$function_name" >/dev/null 2>&1; then
        echo "macOS-only function found in .sh_functions: $function_name" >&2
        exit 1
      fi
    done

    source "$1/.osx_functions"
    for function_name in note remind server phpserver unquarantine mount_ssh; do
      typeset -f "$function_name" >/dev/null 2>&1 || exit 1
      "$function_name" --help >/dev/null || exit 1
      "$function_name" -h >/dev/null || exit 1
    done
  ' _ "$REPOSITORY_ROOT"
done

bash -c '
  source "$1/.bash_functions"
  clear_with_gap --help >/dev/null
  clear_with_gap -h >/dev/null
' _ "$REPOSITORY_ROOT"

zsh -f -c 'source "$1/.zsh_functions"' _ "$REPOSITORY_ROOT"

echo "Function help and platform-placement tests passed."
