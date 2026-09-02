# >>> dotfiles_zsh bashrc >>>
# Managed by dotfiles_zsh. Content outside this block is preserved on upgrades.

# Only configure interactive Bash sessions without stopping any user content
# that follows this managed block.
if [[ $- == *i* ]]; then

  export OSH="${OSH:-$HOME/.oh-my-bash}"

  [[ -r "${HOME}/.sh_theme" ]] && source "${HOME}/.sh_theme"
  OSH_THEME="${DOTFILES_BASH_THEME:-powerbash10k}"
  DISABLE_UPDATE_PROMPT=true
  DISABLE_AUTO_UPDATE=false
  ENABLE_CORRECTION=true
  COMPLETION_WAITING_DOTS=true
  HIST_STAMPS="dd.mm.yyyy"
  HISTSIZE=32768
  HISTFILESIZE=$HISTSIZE
  HISTCONTROL=ignoredups
  HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
  export INPUTRC="$HOME/.bash_inputrc"

  shopt -s nocaseglob
  shopt -s histappend
  shopt -s cdspell
  shopt -s autocd 2>/dev/null || true
  shopt -s globstar 2>/dev/null || true

  # Match the useful overlap with the Powerlevel10k prompt: context, directory,
  # language environments, source control, status, duration, and time.
  THEME_SHOW_SCM=true
  THEME_SHOW_RUBY=true
  THEME_SHOW_PYTHON=true
  THEME_SHOW_CLOCK=true
  THEME_SHOW_EXITCODE=true
  THEME_SHOW_TODO=false
  THEME_SHOW_BATTERY=false
  __PB10K_PROMPT_LOCAL_USER_INFO=false
  __PB10K_TOP_LEFT="user_info dir python ruby scm"
  __PB10K_TOP_RIGHT="exitcode cmd_duration clock"
  __PB10K_BOTTOM="char"

  completions=(git ssh)
  aliases=()
  plugins=(git)

  command -v fzf >/dev/null 2>&1 && plugins+=(fzf)
  command -v zoxide >/dev/null 2>&1 && plugins+=(zoxide)

  if [[ -r "$OSH/oh-my-bash.sh" ]]; then
    source "$OSH/oh-my-bash.sh"
  fi

  [[ -r "${HOME}/.iterm2_shell_integration.bash" ]] && source "${HOME}/.iterm2_shell_integration.bash"

  [[ -r "${HOME}/.motd" ]] && source "${HOME}/.motd"
  [[ -r "${HOME}/.sh_functions" ]] && source "${HOME}/.sh_functions"
  [[ -r "${HOME}/.sh_aliases" ]] && source "${HOME}/.sh_aliases"
  [[ -r "${HOME}/.bash_functions" ]] && source "${HOME}/.bash_functions"
  [[ -r "${HOME}/.bash_aliases" ]] && source "${HOME}/.bash_aliases"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    [[ -r "${HOME}/.osx_functions" ]] && source "${HOME}/.osx_functions"
    [[ -r "${HOME}/.osx_aliases" ]] && source "${HOME}/.osx_aliases"
  fi
fi
# <<< dotfiles_zsh bashrc <<<
