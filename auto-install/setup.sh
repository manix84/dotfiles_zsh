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

# === Logging ===
LOGFILE=~/setup-$(date +%Y%m%d%H%M).log
exec > >(tee -a "$LOGFILE") 2>&1

# === Globals ===
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
USE_SUDO=false
DOTFILES_REF=${DOTFILES_REF:-main}
DOTFILES_RAW_URL="https://raw.githubusercontent.com/manix84/dotfiles_zsh/${DOTFILES_REF}"
FASTFETCH_AVAILABLE=false

# === Helpers ===
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
    if [[ -r /etc/os-release ]] && grep -Eq '^(VERSION_CODENAME=jessie|VERSION_ID="?8)' /etc/os-release; then
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

append_to_zshrc() {
  local line="$1"
  grep -qxF "$line" ~/.zshrc || echo "$line" >> ~/.zshrc
}

backup_file_once() {
  local file="$1"
  [[ ! -f "$file" || -e "$file.backup" ]] || cp "$file" "$file.backup"
}

install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    echo "Already installed: fastfetch"
    return 0
  fi

  local platform_arch=$(detect_platform_arch)
  [[ "$platform_arch" == "unsupported" ]] && { echo "Unsupported platform."; return 1; }

  if [[ "$platform_arch" == "macos-universal" ]]; then
    brew install fastfetch || return 1
    return 0
  fi

  local version=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r '.name')
  local asset_name="fastfetch-${platform_arch}.deb"
  local url="https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/${asset_name}"

  curl -L "$url" -o /tmp/fastfetch.deb && run_as_root apt install -y /tmp/fastfetch.deb && rm /tmp/fastfetch.deb
}

install_oh_my_zsh() {
  RUNZSH=no KEEP_ZSHRC=yes execute_online_script https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
  download_file http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme --output=$ZSH_CUSTOM/themes/bullet-train.zsh-theme

  [[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.backup
  sed -i.bak 's/ZSH_THEME=\"[^"]*\"/ZSH_THEME=\"bullet-train\"/' ~/.zshrc

  append_to_zshrc 'ENABLE_CORRECTION="true"'
  append_to_zshrc 'DISABLE_UPDATE_PROMPT="true"'
  append_to_zshrc 'DISABLE_AUTO_UPDATE="false"'

  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true
  append_to_zshrc 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)'
}

install_fastfetch_configuration() {
  mkdir -p ~/.config/fastfetch
  backup_file_once ~/.config/fastfetch/config.jsonc
  backup_file_once ~/.config/fastfetch/server.jsonc
  backup_file_once ~/.motd
  download_file "$DOTFILES_RAW_URL/.config/fastfetch/config.jsonc" --output ~/.config/fastfetch/config.jsonc
  download_file "$DOTFILES_RAW_URL/.config/fastfetch/server.jsonc" --output ~/.config/fastfetch/server.jsonc
  download_file "$DOTFILES_RAW_URL/.motd" --output ~/.motd
  append_to_zshrc "[[ -f ~/.motd ]] && source ~/.motd"
  chmod 0700 ~/.motd
}

install_nano_highlight() {
  execute_online_script https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
  [[ -f /etc/nanorc ]] && cat /etc/nanorc >> ~/.nanorc
}

change_shell_to_zsh() {
  [[ $SHELL != *zsh ]] && chsh -s "$(which zsh)"
}

# === Main Install Steps ===
configure_privilege_command
install_required_packages zsh git unzip jq curl wget

if install_fastfetch; then
  FASTFETCH_AVAILABLE=true
else
  echo "Fastfetch installation failed; continuing without the Fastfetch MOTD." >&2
fi
install_oh_my_zsh
if [[ $FASTFETCH_AVAILABLE == true ]]; then
  install_fastfetch_configuration
fi
install_nano_highlight
change_shell_to_zsh

zsh
