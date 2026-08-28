# ZSH Dotfiles

An automated terminal setup for macOS and Linux. The installer sets up Zsh,
Oh My Zsh, the Bullet Train theme, useful Zsh plugins, Fastfetch, and Nano
syntax highlighting.

## One-step install

Run one of the following commands. GitHub displays a copy button in the
top-right corner of each command block.

### curl

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

### wget

```bash
bash -c "$(wget -O- https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

### fetch

```bash
bash -c "$(fetch -o - https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

## Administrator access

Installing the required system packages needs administrator privileges:

- For a standard user, the installer uses `sudo` and asks for authentication.
- On a sudo-less system such as a ReadyNAS, enter a root shell first and then
  run one of the installation commands above. When already running as root, the
  installer executes package-manager commands directly without `sudo`.
- A non-root user on a system without `sudo` cannot install the required system
  packages.

The installer writes a timestamped log to the current user's home directory.

For additional details, see the [auto-install documentation](auto-install/README.md)
or review the [installation script](auto-install/setup.sh).
