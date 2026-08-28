# Auto-Install (WIP)
Run the following to pull down and install these dotfiles automatically.

## One-Step Automated Install
Those who want to get started quickly and conveniently may run terminal-setup using the following command:

| Method    | Command                                                                                                     |
|:----------|:------------------------------------------------------------------------------------------------------------|
| **curl**  | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"` |
| **wget**  | `bash -c "$(wget -O- https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"`   |
| **fetch** | `bash -c "$(fetch -o - https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"` |

The installer supports both standard users with `sudo` and systems without
`sudo` when it is run from an existing root shell. On a sudo-less system, first
become root using the method provided by the device, then run one of the commands
above. A non-root user without `sudo` cannot install the required system packages.

## WIP: Still needs adding ##
- [x] https://github.com/manix84/dotfiles_zsh/issues/1
- [x] https://github.com/manix84/dotfiles_zsh/issues/2
  - [x] https://github.com/manix84/dotfiles_zsh/issues/3
  - [x] https://github.com/manix84/dotfiles_zsh/issues/4
  - [x] https://github.com/manix84/dotfiles_zsh/issues/5
- [ ] https://github.com/manix84/dotfiles_zsh/issues/6
- [ ] https://github.com/manix84/dotfiles_zsh/issues/7

**Later improvements/optimisations**
- [ ] https://github.com/manix84/dotfiles_zsh/issues/8
