#!/bin/bash

set -eu
IFS=$'\n\t'

: <<'DISCLAIMER'

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

This script is licensed under the terms of the MIT license.
Unless otherwise noted, code reproduced herein
was written for this script.

- Manix84 -

DISCLAIMER

# Capture this before logging redirects stdout through tee.
INTERACTIVE_TERMINAL=false
if [[ -t 0 && -t 1 ]]; then
  INTERACTIVE_TERMINAL=true
fi

# === Logging ===
LOGFILE=~/setup-$(date +%Y%m%d%H%M).log
exec > >(tee -a "$LOGFILE") 2>&1

# === Globals ===
ZSH_INSTALL_DIR=${ZSH:-$HOME/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH_INSTALL_DIR/custom}
OSH_INSTALL_DIR=${OSH:-$HOME/.oh-my-bash}
USE_SUDO=false
DOTFILES_REF=${DOTFILES_REF:-main}
DOTFILES_RAW_URL="https://raw.githubusercontent.com/manix84/dotfiles_zsh/${DOTFILES_REF}"
INSTALL_MODE=fresh
INSTALL_MARKER="$HOME/.dotfiles_zsh-installed"
REQUESTED_SHELL=auto
TARGET_SHELL=""
PLATFORM_OS=$(uname -s)

# === Helpers ===
show_usage() {
  cat <<'EOF'
Usage: setup.sh [--shell auto|bash|zsh]

Options:
  --shell auto   Reuse the recorded or current login shell (default).
  --shell bash   Install and activate Bash with Oh My Bash.
  --shell zsh    Install and activate Zsh with Oh My Zsh.
  --bash         Shorthand for --shell bash.
  --zsh          Shorthand for --shell zsh.
  -h, --help     Show this help.
EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --shell)
        [[ $# -ge 2 ]] || { echo "--shell requires auto, bash, or zsh." >&2; return 1; }
        REQUESTED_SHELL="$2"
        shift 2
        ;;
      --shell=*) REQUESTED_SHELL="${1#--shell=}"; shift ;;
      --bash) REQUESTED_SHELL=bash; shift ;;
      --zsh) REQUESTED_SHELL=zsh; shift ;;
      -h|--help) show_usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; show_usage >&2; return 1 ;;
    esac
  done

  case "$REQUESTED_SHELL" in
    auto|bash|zsh) ;;
    *) echo "Unsupported shell selection: $REQUESTED_SHELL" >&2; return 1 ;;
  esac
}

resolve_target_shell() {
  local recorded_shell=""
  local login_shell=""

  if [[ "$REQUESTED_SHELL" != auto ]]; then
    TARGET_SHELL="$REQUESTED_SHELL"
  else
    if [[ -r "$INSTALL_MARKER" ]]; then
      recorded_shell=$(sed -n 's/^shell=//p' "$INSTALL_MARKER" | head -n 1)
    fi

    case "$recorded_shell" in
      bash|zsh) TARGET_SHELL="$recorded_shell" ;;
    esac

    if [[ -z "$TARGET_SHELL" ]]; then
      login_shell=${SHELL:-}
      login_shell=${login_shell##*/}
      case "$login_shell" in
        bash|zsh) TARGET_SHELL="$login_shell" ;;
      esac
    fi

    if [[ -z "$TARGET_SHELL" ]]; then
      if [[ "$PLATFORM_OS" == Darwin ]]; then
        TARGET_SHELL=zsh
      else
        TARGET_SHELL=bash
      fi
    fi
  fi

  echo "Selected shell: $TARGET_SHELL"
}

detect_install_mode() {
  if [[ -e "$INSTALL_MARKER" || -e "$ZSH_INSTALL_DIR" || -e "$OSH_INSTALL_DIR" || \
        -e "$HOME/.zshrc" || -e "$HOME/.bashrc" || -e "$HOME/.bash_profile" || \
        -e "$HOME/.sh_functions" || -e "$HOME/.osx_functions" || -e "$HOME/.gitconfig" ]]; then
    INSTALL_MODE=upgrade
    echo "Existing shell setup detected; running in upgrade mode."
    echo "Existing dotfiles will be preserved and only missing files will be installed."
  else
    echo "No existing shell setup detected; running in fresh-install mode."
  fi
}

is_debian_jessie() {
  [[ -r /etc/os-release ]] && grep -Eq '^(VERSION_CODENAME=jessie|VERSION_ID="?8)' /etc/os-release
}

configure_privilege_command() {
  if [[ $EUID -eq 0 ]]; then
    echo "Running as root; sudo is not required."
  elif command -v sudo >/dev/null 2>&1; then
    sudo -v || { echo "Sudo authentication failed." >&2; return 1; }
    USE_SUDO=true
  else
    echo "Administrator privileges are required. Re-run this installer as root or install sudo." >&2
    return 1
  fi
}

run_as_root() {
  if [[ $USE_SUDO == true ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

detect_platform_arch() {
  local os="$(uname -s)"
  local arch="$(uname -m)"

  case "$os" in
    Darwin)
      echo "macos-universal";;
    Linux)
      case "$arch" in
        aarch64) echo "linux-aarch64";;
        armv6l) echo "linux-armv6l";;
        armv7l) echo "linux-armv7l";;
        x86_64) echo "linux-amd64";;
        ppc64le|riscv64|s390x) echo "linux-$arch";;
        i386|i686) echo "sunos-i386";;
        *) echo "unsupported";;
      esac;;
    *) echo "unsupported";;
  esac
}

install_package() {
  local package_manager=""

  if command -v apt >/dev/null; then package_manager="apt"
  elif command -v yum >/dev/null; then package_manager="yum"
  elif command -v dnf >/dev/null; then package_manager="dnf"
  elif command -v zypper >/dev/null; then package_manager="zypper"
  elif command -v pacman >/dev/null; then package_manager="pacman"
  elif command -v brew >/dev/null; then package_manager="brew"
  elif command -v apk >/dev/null; then package_manager="apk"
  else echo "No supported package manager found!" >&2; return 1
  fi

  echo "Using $package_manager to install: $@"
  case "$package_manager" in
    apt) run_as_root apt-get update && run_as_root apt-get install -y "$@";;
    yum) run_as_root yum install -y "$@";;
    dnf) run_as_root dnf install -y "$@";;
    zypper) run_as_root zypper install -y "$@";;
    pacman) run_as_root pacman -Sy --noconfirm "$@";;
    brew) brew install "$@";;
    apk) run_as_root apk add "$@";;
    *) echo "Unsupported package manager: $package_manager" >&2; return 1;;
  esac
}

install_required_packages() {
  local package=""
  local missing_count=0
  local missing_packages=()

  for package in "$@"; do
    if command -v "$package" >/dev/null 2>&1; then
      echo "Already installed: $package"
    else
      missing_packages[$missing_count]="$package"
      missing_count=$((missing_count + 1))
    fi
  done

  if [[ $missing_count -eq 0 ]]; then
    echo "All required packages are already available; skipping package installation."
    return 0
  fi

  if ! install_package "${missing_packages[@]}"; then
    if is_debian_jessie; then
      echo >&2
      echo "Debian Jessie is end-of-life and its packages have moved to archive.debian.org." >&2
      echo "Update this device's APT sources using the ReadyNAS instructions in the project README, then rerun the installer." >&2
    fi
    return 1
  fi
}

download_file() {
  local url="" output=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --output=*) output="${1#--output=}";;
      --output) output="$2"; shift;;
      *) url="$1";;
    esac
    shift
  done

  [[ -z "$url" ]] && { echo "No URL provided." >&2; return 1; }

  if command -v wget &>/dev/null; then wget -O "$output" "$url"
  elif command -v curl &>/dev/null; then curl -Lo "$output" "$url"
  else echo "No download utility found." >&2; return 1
  fi
}

execute_online_script() {
  local url="$1"
  if command -v curl >/dev/null; then bash -c "$(curl -fsSL $url)"
  elif command -v wget >/dev/null; then bash -c "$(wget -qO- $url)"
  else echo "No supported downloader found." >&2; return 1
  fi
}

merge_alias_file() {
  local relative_path="$1"
  local target="$2"
  local downloaded_file="$3"
  local alias_dump="${downloaded_file}.aliases"
  local alias_definition=""
  local alias_name=""
  local added_count=0

  download_file "$DOTFILES_RAW_URL/$relative_path" --output "$downloaded_file"

  case "$relative_path" in
    .zsh_aliases)
      sed -nE '/^[[:space:]]*alias[[:space:]]+/p' "$downloaded_file" > "$alias_dump"
      ;;
    *)
      bash --noprofile --norc -c 'source "$1"; alias -p' _ "$downloaded_file" > "$alias_dump"
      ;;
  esac

  while IFS= read -r alias_definition; do
    alias_name=$(printf '%s\n' "$alias_definition" | sed -nE \
      's/^[[:space:]]*alias[[:space:]]+(--[[:space:]]+)?([^=[:space:]]+)=.*/\2/p')
    [[ -n "$alias_name" ]] || continue

    if sed -nE 's/^[[:space:]]*alias[[:space:]]+(--[[:space:]]+)?([^=[:space:]]+)=.*/\2/p' "$target" | \
        grep -Fxq -- "$alias_name"; then
      continue
    fi

    if [[ $added_count -eq 0 ]]; then
      printf '\n# Aliases added by dotfiles_zsh. Existing aliases take precedence.\n' >> "$target"
    fi
    printf '%s\n' "$alias_definition" >> "$target"
    added_count=$((added_count + 1))
  done < "$alias_dump"

  rm -f "$downloaded_file" "$alias_dump"
  echo "Merged $added_count new aliases into: $target"
}

merge_managed_file() {
  local relative_path="$1"
  local target="$2"
  local downloaded_file="$3"
  local merged_file="${downloaded_file}.merged"
  local start_marker=""
  local end_marker=""

  case "$relative_path" in
    .bashrc)
      start_marker="# >>> dotfiles_zsh bashrc >>>"
      end_marker="# <<< dotfiles_zsh bashrc <<<"
      ;;
    .bash_profile)
      start_marker="# >>> dotfiles_zsh bash-profile >>>"
      end_marker="# <<< dotfiles_zsh bash-profile <<<"
      ;;
    *)
      echo "No managed-block definition for $relative_path" >&2
      return 1
      ;;
  esac

  download_file "$DOTFILES_RAW_URL/$relative_path" --output "$downloaded_file"

  if grep -Fqx "$start_marker" "$target" && grep -Fqx "$end_marker" "$target"; then
    awk -v start="$start_marker" -v end="$end_marker" -v replacement="$downloaded_file" '
      function emit_replacement(line) {
        while ((getline line < replacement) > 0) print line
        close(replacement)
      }
      $0 == start { emit_replacement(); skipping=1; found=1; next }
      skipping && $0 == end { skipping=0; next }
      !skipping { print }
      END { if (!found) { print ""; emit_replacement() } }
    ' "$target" > "$merged_file"
  else
    cp "$target" "$merged_file"
    printf '\n' >> "$merged_file"
    cat "$downloaded_file" >> "$merged_file"
  fi

  mv "$merged_file" "$target"
  rm -f "$downloaded_file"
  echo "Updated managed shell configuration in: $target"
}

install_dotfile() {
  local relative_path="$1"
  local target="$HOME/$relative_path"
  local temporary_file="${target}.dotfiles_zsh.tmp.$$"

  if [[ $INSTALL_MODE == upgrade && ( -e "$target" || -L "$target" ) ]]; then
    if [[ -L "$target" || ! -f "$target" ]]; then
      echo "Preserving existing non-regular dotfile: $target"
      return 0
    fi

    case "$relative_path" in
      .sh_aliases|.bash_aliases|.zsh_aliases|.osx_aliases)
        merge_alias_file "$relative_path" "$target" "$temporary_file"
        ;;
      .bashrc|.bash_profile)
        merge_managed_file "$relative_path" "$target" "$temporary_file"
        ;;
      *)
        echo "Preserving existing dotfile: $target"
        ;;
    esac
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  download_file "$DOTFILES_RAW_URL/$relative_path" --output "$temporary_file"
  mv "$temporary_file" "$target"
  [[ $relative_path != .motd ]] || chmod 0700 "$target"
  echo "Installed dotfile: $target"
}

install_dotfiles() {
  install_dotfile .sh_theme
  install_dotfile .sh_functions
  install_dotfile .sh_aliases

  case "$TARGET_SHELL" in
    bash)
      install_dotfile .bashrc
      install_dotfile .bash_profile
      install_dotfile .bash_functions
      install_dotfile .bash_aliases
      install_dotfile .bash_inputrc
      ;;
    zsh)
      install_dotfile .zshrc
      install_dotfile .zsh_functions
      install_dotfile .zsh_aliases
      ;;
  esac

  if [[ "$PLATFORM_OS" == "Darwin" ]]; then
    install_dotfile .osx_functions
    install_dotfile .osx_aliases
  else
    echo "Skipping macOS-specific dotfiles on this platform."
  fi

  install_dotfile .gitconfig
  install_dotfile .gitignore
  install_dotfile .gitattributes
  install_dotfile .motd
  install_dotfile .config/fastfetch/config.jsonc
  install_dotfile .config/fastfetch/server.jsonc
}

record_install() {
  printf 'dotfiles_ref=%s\nshell=%s\ninstalled_at=%s\n' \
    "$DOTFILES_REF" "$TARGET_SHELL" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$INSTALL_MARKER"
}

install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    echo "Already installed: fastfetch"
    return 0
  fi

  if is_debian_jessie; then
    echo "Fastfetch requires a newer libc than Debian Jessie provides; skipping it." >&2
    return 1
  fi

  local platform_arch=$(detect_platform_arch)
  [[ "$platform_arch" == "unsupported" ]] && { echo "Unsupported platform."; return 1; }

  if [[ "$platform_arch" == "macos-universal" ]]; then
    brew install fastfetch || return 1
    return 0
  fi

  local asset_name="fastfetch-${platform_arch}.deb"
  local url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/${asset_name}"

  if ! curl -fL "$url" -o /tmp/fastfetch.deb; then
    return 1
  fi

  if ! run_as_root apt install -y /tmp/fastfetch.deb; then
    rm -f /tmp/fastfetch.deb
    return 1
  fi

  rm -f /tmp/fastfetch.deb
}

install_framework_checkout() {
  local display_name="$1"
  local install_dir="$2"
  local marker_file="$3"
  local repository_url="$4"
  local environment_name="$5"

  if [[ -f "$install_dir/$marker_file" ]]; then
    echo "Already installed: $display_name ($install_dir)"
  elif [[ -e "$install_dir" ]]; then
    echo "The $display_name path exists but is not a valid installation: $install_dir" >&2
    echo "Move it aside or set $environment_name to a different installation path, then rerun the installer." >&2
    return 1
  else
    git clone --depth=1 "$repository_url" "$install_dir"
  fi
}

install_zsh_plugin() {
  local plugin_name="$1"
  local marker_file="$2"
  local repository_url="$3"
  local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"

  if [[ -f "$plugin_dir/$marker_file" ]]; then
    echo "Already installed: $plugin_name ($plugin_dir)"
  elif [[ -e "$plugin_dir" ]]; then
    echo "The $plugin_name path exists but is not a valid plugin: $plugin_dir" >&2
    return 1
  else
    git clone --depth=1 "$repository_url" "$plugin_dir"
  fi
}

install_oh_my_zsh() {
  install_framework_checkout "Oh My Zsh" "$ZSH_INSTALL_DIR" oh-my-zsh.sh \
    https://github.com/ohmyzsh/ohmyzsh.git ZSH

  mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"
  install_framework_checkout "Powerlevel10k" "$ZSH_CUSTOM/themes/powerlevel10k" \
    powerlevel10k.zsh-theme https://github.com/romkatv/powerlevel10k.git \
    ZSH_CUSTOM

  install_zsh_plugin zsh-autosuggestions zsh-autosuggestions.zsh \
    https://github.com/zsh-users/zsh-autosuggestions.git
  install_zsh_plugin zsh-syntax-highlighting zsh-syntax-highlighting.zsh \
    https://github.com/zsh-users/zsh-syntax-highlighting.git
}

install_oh_my_bash() {
  install_framework_checkout "Oh My Bash" "$OSH_INSTALL_DIR" oh-my-bash.sh \
    https://github.com/ohmybash/oh-my-bash.git OSH
}

install_shell_framework() {
  case "$TARGET_SHELL" in
    bash) install_oh_my_bash ;;
    zsh) install_oh_my_zsh ;;
  esac
}

install_nano_highlight() {
  execute_online_script https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
  [[ -f /etc/nanorc ]] && cat /etc/nanorc >> ~/.nanorc
}

change_login_shell() {
  local shell_path=""
  local current_shell=${SHELL:-}
  if ! shell_path=$(command -v "$TARGET_SHELL"); then
    echo "Selected shell is not installed or not on PATH: $TARGET_SHELL" >&2
    return 1
  fi

  if [[ ${current_shell##*/} == "$TARGET_SHELL" ]]; then
    echo "$TARGET_SHELL is already the login shell."
    return 0
  fi

  chsh -s "$shell_path"
}

start_selected_shell() {
  if [[ $INTERACTIVE_TERMINAL == true ]]; then
    echo "Setup complete. Starting a fresh $TARGET_SHELL login shell."
    exec "$TARGET_SHELL" -l
  fi

  echo "Setup complete. Start the selected shell with: $TARGET_SHELL -l"
}

# === Main Install Steps ===
parse_arguments "$@"
resolve_target_shell
detect_install_mode
configure_privilege_command
install_required_packages "$TARGET_SHELL" git unzip curl wget

if ! install_fastfetch; then
  echo "Fastfetch installation failed; continuing without the Fastfetch MOTD." >&2
fi
install_shell_framework
install_dotfiles
install_nano_highlight
change_login_shell
record_install

start_selected_shell
