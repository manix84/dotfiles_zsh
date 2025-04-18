###Install OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &
INSTALL_PID=$!
wait $INSTALL_PID

### Install OhMyZSH-BulletTrain
export ZSH_CUSTOM=~/.oh-my-zsh/custom
wget --output-document=$ZSH_CUSTOM/themes/bullet-train.zsh-theme http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme
cp ~/.zshrc ~/.zshrc.backup
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bullet-train"/g' ~/.zshrc
echo 'ENABLE_CORRECTION="true"' >>  ~/.zshrc
echo 'DISABLE_UPDATE_PROMPT="true"' >> ~/.zshrc
echo 'DISABLE_AUTO_UPDATE="false"' >> ~/.zshrc

### Install MOTD - Neofetch
echo "printf '\033[2J'\nneofetch" > ~/.motd
echo "\nif [ -f ~/.motd ]; then\n  source ~/.motd\nfi" >> ~/.zshrc
chown 0700 ~/.motd

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
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
cat /etc/nanorc >> ~/.nanorc

### Change shell to ZSH
chsh -s "$(which zsh)"

### Switch to ZSH
zsh
