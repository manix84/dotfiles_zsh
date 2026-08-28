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
DOTFILES_REF=${DOTFILES_REF:-main}
DOTFILES_RAW_URL="https://raw.githubusercontent.com/manix84/dotfiles_zsh/${DOTFILES_REF}"

# === Helpers ===
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
  if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Fastfetch is not installed; skipping its configuration." >&2
    return 0
  fi

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
install_oh_my_zsh
install_fastfetch_configuration
install_nano_highlight
change_shell_to_zsh

zsh
