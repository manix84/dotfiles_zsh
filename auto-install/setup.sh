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
USE_SUDO=false
DOTFILES_REF=${DOTFILES_REF:-main}
DOTFILES_RAW_URL="https://raw.githubusercontent.com/manix84/dotfiles_zsh/${DOTFILES_REF}"
INSTALL_MODE=fresh
INSTALL_MARKER="$HOME/.dotfiles_zsh-installed"

# === Helpers ===
detect_install_mode() {
  if [[ -e "$INSTALL_MARKER" || -e "$ZSH_INSTALL_DIR" || -e "$HOME/.zshrc" || \
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

install_dotfile() {
  local relative_path="$1"
  local target="$HOME/$relative_path"
  local temporary_file="${target}.dotfiles_zsh.tmp.$$"

  if [[ $INSTALL_MODE == upgrade && -e "$target" ]]; then
    echo "Preserving existing dotfile: $target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  download_file "$DOTFILES_RAW_URL/$relative_path" --output "$temporary_file"
  mv "$temporary_file" "$target"
  [[ $relative_path != .motd ]] || chmod 0700 "$target"
  echo "Installed dotfile: $target"
}

install_dotfiles() {
  install_dotfile .zshrc
  install_dotfile .sh_functions
  install_dotfile .osx_functions
  install_dotfile .gitconfig
  install_dotfile .gitignore
  install_dotfile .gitattributes
  install_dotfile .motd
  install_dotfile .config/fastfetch/config.jsonc
  install_dotfile .config/fastfetch/server.jsonc
}

record_install() {
  printf 'dotfiles_ref=%s\ninstalled_at=%s\n' \
    "$DOTFILES_REF" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$INSTALL_MARKER"
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

install_oh_my_zsh() {
  if [[ -f "$ZSH_INSTALL_DIR/oh-my-zsh.sh" ]]; then
    echo "Already installed: Oh My Zsh ($ZSH_INSTALL_DIR)"
  elif [[ -e "$ZSH_INSTALL_DIR" ]]; then
    echo "The Oh My Zsh path exists but is not a valid installation: $ZSH_INSTALL_DIR" >&2
    echo "Move it aside or set ZSH to a different installation path, then rerun the installer." >&2
    return 1
  else
    ZSH="$ZSH_INSTALL_DIR" RUNZSH=no KEEP_ZSHRC=yes execute_online_script https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
  fi

  download_file http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme --output=$ZSH_CUSTOM/themes/bullet-train.zsh-theme

  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true
}

install_nano_highlight() {
  execute_online_script https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
  [[ -f /etc/nanorc ]] && cat /etc/nanorc >> ~/.nanorc
}

change_shell_to_zsh() {
  local zsh_path=""
  zsh_path=$(command -v zsh)

  if [[ ${SHELL:-} == *zsh ]]; then
    echo "Zsh is already the login shell."
    return 0
  fi

  chsh -s "$zsh_path"
}

start_zsh() {
  if [[ $INTERACTIVE_TERMINAL == true ]]; then
    echo "Setup complete. Starting a fresh Zsh login shell."
    exec zsh -l
  fi

  echo "Setup complete. Start Zsh with: zsh -l"
}

# === Main Install Steps ===
detect_install_mode
configure_privilege_command
install_required_packages zsh git unzip curl wget

if ! install_fastfetch; then
  echo "Fastfetch installation failed; continuing without the Fastfetch MOTD." >&2
fi
install_oh_my_zsh
install_dotfiles
install_nano_highlight
change_shell_to_zsh
record_install

start_zsh
