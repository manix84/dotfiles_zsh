function _bash_function_help() {
  case "$1" in
    clear_with_gap) cat <<'EOF'
Usage: clear_with_gap
Add a screen-height gap to the terminal scrollback, then clear the screen.
The cclear alias provides a shorter name for this Bash-specific function.
EOF
      ;;
  esac
}

function clear_with_gap() {
  if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    _bash_function_help clear_with_gap
    return
  fi

  local line_count
  line_count=$(tput lines)
  local line=0
  while (( line < line_count )); do
    printf '\n'
    line=$((line + 1))
  done
  command clear
}
