# Dotfiles

Portable, automated terminal setup for Bash and Zsh on macOS and Linux. The
installer detects the environment, deploys only the files that apply to it,
configures the matching shell framework and prompt, and installs Fastfetch and
Nano syntax highlighting.

## Supported environments

| Shell | Framework | Prompt | Shell files |
| --- | --- | --- | --- |
| Bash | Oh My Bash | Powerbash10k | `.bash_*` |
| Zsh | Oh My Zsh | Powerlevel10k | `.zsh_*` |

Both environments also receive portable `.sh_*` files. macOS additionally
receives `.osx_*` files; these are not installed on Linux. Repository metadata
and editor settings are never deployed as home-directory dotfiles.

Theme selection lives in `~/.sh_theme`. Its defaults are `powerbash10k` for
Bash and `powerlevel10k/powerlevel10k` for Zsh. Change
`DOTFILES_BASH_THEME` or `DOTFILES_ZSH_THEME` there to use another theme
provided by the corresponding framework.

## One-step install

Run one of the following commands. GitHub displays a copy button in the
top-right corner of each command block. The bootstrap script runs with Bash,
but it can install and configure either supported shell.

### Automatic

Detect the existing or platform-default shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

### Bash

Explicitly install the Bash environment:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)" -- --bash
```

### Zsh

Explicitly install the Zsh environment:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)" -- --zsh
```

### Alternative download commands

Use `wget` or `fetch` for automatic shell selection when `curl` is unavailable:

```bash
bash -c "$(wget -O- https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

```bash
bash -c "$(fetch -o - https://raw.githubusercontent.com/manix84/dotfiles_zsh/main/auto-install/setup.sh)"
```

## Shell selection

By default, the installer reuses the shell recorded by a previous successful
run, then the current Bash or Zsh login shell. If neither identifies a supported
shell, it defaults to Zsh on macOS and Bash on Linux.

The explicit commands above use the `--bash` and `--zsh` shorthands. The full
option is `--shell auto|bash|zsh`, which also works with local installer
checkouts.

Powerbash10k and Powerlevel10k are separate Bash and Zsh themes rather than two
versions of the same project. Their prompts use the closest practical shared
layout: user/SSH context, directory, Python and Ruby environments, source
control, exit status, command duration, clock, and a separate prompt character.
Powerlevel10k offers some additional capabilities that Powerbash10k does not
provide; those remain native Zsh features instead of being simulated with
custom Bash prompt code.

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

At the end of an interactive run, the installer starts a fresh login session of
the selected shell so its framework and configuration take effect immediately.

## Fresh installs and upgrades

The files are organized by where they apply:

- `.sh_*` contains portable aliases and functions shared by Bash and Zsh.
- `.bash_*` contains Bash configuration, aliases, functions, and input settings.
- `.zsh_*` contains Zsh configuration, aliases, and functions.
- `.osx_*` contains macOS-only aliases and functions for either shell.

On a fresh account, the installer copies the applicable groups along with Git
configuration, global Git ignore/attributes files, MOTD, and Fastfetch profiles.
It never installs Bash files into a Zsh environment, Zsh files into a Bash
environment, or macOS files onto Linux.

Repository-only development metadata, such as `.vscode/`, is not part of the
installer's explicit dotfile list and is never copied into the home directory.

If it detects an existing shell setup, it switches to upgrade mode. Existing
dotfiles are preserved and only missing files are installed. Existing alias
files are merged by alias name: new project aliases are appended, while an
existing alias with the same name is left unchanged. Managed blocks in existing
`.bashrc` and `.bash_profile` files are added or refreshed without replacing
content outside those blocks. Repeated runs therefore do not duplicate aliases,
startup blocks, or replace local customizations. A successful run records the
installed ref, selected shell, and timestamp in `~/.dotfiles_zsh-installed`;
accounts installed by older versions are also recognized from their existing
shell setup or dotfiles.

A valid existing Oh My Bash or Oh My Zsh installation is reused. An existing
framework directory that is not a valid installation is left untouched and
reported for manual review. Both frameworks use validated shallow Git clones;
their upstream installers are not invoked and cannot replace shell startup
files or change the login shell.

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
FASTFETCH_PROFILE=server "$SHELL"
```

To make an override persistent, export `FASTFETCH_PROFILE` in `.bashrc` or
`.zshrc`, as appropriate.
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
