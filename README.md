# ZSH Dotfiles

An automated terminal setup for macOS and Linux. The installer deploys the
tracked dotfiles and sets up Zsh, Oh My Zsh, the Bullet Train theme, useful Zsh
plugins, Fastfetch, and Nano syntax highlighting.

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
Fastfetch and its MOTD are optional; a failure to install Fastfetch does not
prevent the remaining shell setup from completing. Fastfetch is skipped on
Debian Jessie because current releases require a newer system C library.

At the end of an interactive run, the installer starts a fresh Zsh login shell
so the updated Oh My Zsh configuration takes effect immediately.

## Fresh installs and upgrades

On a fresh account, the installer copies the project's `.zshrc`, shell
functions, Git configuration, global Git ignore/attributes files, MOTD, and
Fastfetch profiles into the matching paths under the home directory.

If it detects an existing shell setup, it switches to upgrade mode. Existing
dotfiles are preserved and only missing files are installed, so rerunning the
installer does not replace local customizations. A successful run records the
installed ref and timestamp in `~/.dotfiles_zsh-installed`; accounts installed
by older versions are also recognized from their existing Zsh or dotfiles.

A valid existing Oh My Zsh installation is reused. An existing directory that
does not contain Oh My Zsh is left untouched and reported for manual review.

### ReadyNAS OS 6 and Debian Jessie

ReadyNAS OS 6 uses Debian Jessie. Jessie is end-of-life, so its packages are no
longer available from the normal Debian mirrors. The installer skips package
installation when all required commands are already present. If a package is
missing, update the retired Debian entries in `/etc/apt/sources.list` from a root
shell before running the installer again.

First, back up the existing source list:

```bash
cp -a /etc/apt/sources.list /etc/apt/sources.list.before-jessie-archive
```

Replace only the retired Debian mirror URLs while leaving the ReadyNAS package
source intact:

```bash
sed -i \
  -e 's|http://security.debian.org|http://archive.debian.org/debian-security|' \
  -e 's|http://mirrors.edge.kernel.org/debian|http://archive.debian.org/debian|' \
  -e 's|http://mirrors.kernel.org/debian|http://archive.debian.org/debian|' \
  /etc/apt/sources.list
```

Then refresh the archived package indexes:

```bash
apt-get -o Acquire::Check-Valid-Until=false update
```

Archived Jessie packages no longer receive security updates. Upgrading the
device to a supported platform remains preferable where possible.

The official Fastfetch ARMv7 binaries require glibc 2.34, while Jessie provides
glibc 2.19. The installer will not replace this core system library because doing
so could break the ReadyNAS operating system. Supporting Fastfetch there requires
a separately maintained ARMv7 binary built against the legacy Jessie runtime.

## Fastfetch profiles

The installer provides two profiles:

- `workstation` is the default configuration for a local laptop or desktop. It
  includes graphical-session, GPU, battery, and power information.
- `server` is a compact operational view for remote and headless Linux systems.
  It focuses on uptime, CPU usage, load, memory, disks, networking, and processes.

The shell MOTD selects `server` for SSH sessions and headless Linux systems, and
`workstation` for local graphical sessions. Override the selection when needed:

```bash
FASTFETCH_PROFILE=server zsh
```

To make an override persistent, export `FASTFETCH_PROFILE` in `~/.zshrc`.
Additional profiles can be added as `~/.config/fastfetch/<name>.jsonc` and
selected by setting `FASTFETCH_PROFILE=<name>`.

For additional details, see the [auto-install documentation](auto-install/README.md)
or review the [installation script](auto-install/setup.sh).

## Project information

- [What's new](WHATNEW.md)
- [Contributing](.github/CONTRIBUTING.md)
- [Support](.github/SUPPORT.md)
- [Security policy](.github/SECURITY.md)
- [Privacy](PRIVACY.md)
- [Code of conduct](.github/CODE_OF_CONDUCT.md)
