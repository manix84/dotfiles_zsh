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

required_packages=[]

### Force SUDO Authentication
sudo -v || { echo 'SUDO Authentication Failed' ; exit 1; }

### Package Installer
# function install_package {
#   sudo apt -y install -qq @[0]
# }
# function download_run_shell {}

### Install ZSH
# install_package zsh
### Install GIT
# install_package git
### Install unZIP
# install_package unzip
### Install NeoFetch (should be optional)
# install_package neofetch
sudo apt install -y -qq zsh git neofetch wget unzip

### Find out downloader
# find_download_app()

###Install OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &
INSTALL_PID=$!
wait $INSTALL_PID

### Install OhMyZSH-BulletTrain
export ZSH_CUSTOM=~/.oh-my-zsh/custom
wget --output-document=$ZSH_CUSTOM/themes/bullet-train.zsh-theme http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme
sed -i".backup" 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bullet-train"/g' ~/.zshrc

### Install MOTD - Neofetch
echo "printf '\033[2J'\nneofetch" > ~/.motd
echo "\nif [ -f ~/.motd ]; then\n  source ~/.motd\nfi" >> ~/.zshrc
sudo chown 0700 ~/.motd

### Setup Neofetch ###
cp ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.backup
sed -i 's/# info "Local IP"/info "Local IP"/g' ~/.config/neofetch/config.conf
sed -i 's/# info "Public IP"/info "Public IP"/g' ~/.config/neofetch/config.conf
sed -i 's/# info "CPU Usage"/info "CPU Usage"/g' ~/.config/neofetch/config.conf
sed -i 's/# info "Disk"/info "Disk"/g' ~/.config/neofetch/config.conf

### Setup Nano ###
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
cat /etc/nanorc >> ~/.nanorc

### Change shell to ZSH
sudo chsh -s "$(which zsh)"

### Switch to ZSH
zsh

