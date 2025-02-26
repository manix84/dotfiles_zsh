#!/bin/bash

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

### Force SUDO Authentication
sudo -v || { echo 'SUDO Authentication Failed' ; exit 1; }

### Package Installer
install_package() {
    local package_manager=""
    
    if command -v apt >/dev/null 2>&1; then
        package_manager="apt"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
    elif command -v brew >/dev/null 2>&1; then
        package_manager="brew"
    elif command -v apk >/dev/null 2>&1; then
        package_manager="apk"
    else
        echo "Error: No supported package manager found!" >&2
        return 1
    fi
    
    echo "Using $package_manager to install: $@"
    case "$package_manager" in
        apt)
            sudo apt update && sudo apt install -y "$@"
            ;;
        yum)
            sudo yum install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        zypper)
            sudo zypper install -y "$@"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm "$@"
            ;;
        brew)
            brew install "$@"
            ;;
        apk)
            sudo apk add "$@"
            ;;
        *)
            echo "Error: Unsupported package manager: $package_manager" >&2
            return 1
            ;;
    esac
}

### File downloader
download_file() {
    local url="" output=""
    local downloader=""
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --output=*)
                output="${1#--output=}"
                ;;
            --output)
                output="$2"
                shift
                ;;
            *)
                url="$1"
                ;;
        esac
        shift
    done
    
    if [[ -z "$url" ]]; then
        echo "Error: No URL provided." >&2
        return 1
    fi
    
    # Determine available downloader
    if command -v wget &>/dev/null; then
        downloader="wget"
    elif command -v curl &>/dev/null; then
        downloader="curl"
    elif command -v fetch &>/dev/null; then
        downloader="fetch"
    elif command -v aria2c &>/dev/null; then
        downloader="aria2c"
    elif command -v httpie &>/dev/null; then
        downloader="http"
    else
        echo "Error: No supported download utility found (wget, curl, fetch, aria2c, httpie)." >&2
        return 1
    fi
    
    # Download file based on the selected tool
    if [[ -n "$output" ]]; then
        case "$downloader" in
            wget)
                wget --output-document="$output" "$url"
                ;;
            curl)
                curl -o "$output" "$url"
                ;;
            fetch)
                fetch -o "$output" "$url"
                ;;
            aria2c)
                aria2c -o "$output" "$url"
                ;;
            http)
                http --download "$url" --output "$output"
                ;;
        esac
    else
        case "$downloader" in
            wget)
                wget "$url"
                ;;
            curl)
                curl -O "$url"
                ;;
            fetch)
                fetch "$url"
                ;;
            aria2c)
                aria2c "$url"
                ;;
            http)
                http --download "$url"
                ;;
        esac
    fi
}

### Execute Online Scripts
execute_online_script() {
    local url="$1"
    local downloader=""

    # Determine which downloader is available
    if command -v curl >/dev/null 2>&1; then
        downloader="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        downloader="wget -qO-"
    elif command -v fetch >/dev/null 2>&1; then
        downloader="fetch -o -"
    elif command -v http >/dev/null 2>&1; then
        downloader="http --body"
    elif command -v aria2c >/dev/null 2>&1; then
        downloader="aria2c -q -o -"
    elif command -v axel >/dev/null 2>&1; then
        downloader="axel -o -"
    elif command -v lftp >/dev/null 2>&1; then
        downloader="lftp -c 'get -O -'"
    else
        echo "Error: No supported downloader found (curl, wget, fetch, http, aria2c, axel, lftp)" >&2
        return 1
    fi

    # Execute the script in a separate process and get its PID
    bash -c "$($downloader \"$url\")" & 
    pid=$!
    echo $pid
}


install_package zsh git unqip fastfetch

### Find out downloader
# find_download_app()

###Install OhMyZSH
OMZSH_INSTALL_PID=$(execute_online_script https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)
wait $OMZSH_INSTALL_PID

### Install OhMyZSH-BulletTrain
export ZSH_CUSTOM=~/.oh-my-zsh/custom

download_file http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme --output=$ZSH_CUSTOM/themes/bullet-train.zsh-theme

cp ~/.zshrc ~/.zshrc.backup

sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bullet-train"/g' ~/.zshrc
echo 'ENABLE_CORRECTION="true"' >>  ~/.zshrc
echo 'DISABLE_UPDATE_PROMPT="true"' >> ~/.zshrc
echo 'DISABLE_AUTO_UPDATE="false"' >> ~/.zshrc

### Install MOTD - Neofetch
echo "printf '\033[2J'\nneofetch" > ~/.motd
echo "\nif [ -f ~/.motd ]; then\n  source ~/.motd\nfi" >> ~/.zshrc
sudo chown 0700 ~/.motd

### Setup Neofetch ###
# cp ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.backup
# sed -i 's/# info "Local IP"/info "Local IP"/g' ~/.config/neofetch/config.conf
# sed -i 's/# info "Public IP"/info "Public IP"/g' ~/.config/neofetch/config.conf
# sed -i 's/# info "CPU Usage"/info "CPU Usage"/g' ~/.config/neofetch/config.conf
# sed -i 's/# info "Disk"/info "Disk"/g' ~/.config/neofetch/config.conf

### Setup FastFetch ###
# mkdir -p ~/.config/fastfetch/
# wget --output-document=~/.config/fastfetch/config.jsonc https://raw.githubusercontent.com/manix84/dotfiles_zsh/refs/heads/main/.config/fastfetch/config.jsonc

### Setup Nano ###
NANO_INSTALL_PID=$(execute_online_script https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh)
wait $NANO_INSTALL_PID
cat /etc/nanorc >> ~/.nanorc

### Change shell to ZSH
chsh -s "$(which zsh)"

### Switch to ZSH
zsh

