# What's New

This file highlights user-facing changes. For the complete history, see the
[commit history](https://github.com/manix84/dotfiles_zsh/commits/main/).

## Unreleased

### Improved

- Added support for running the installer from an existing root shell on
  sudo-less systems such as ReadyNAS.
- Improved compatibility with the older Bash versions found on some NAS
  devices.
- Avoided unnecessary package-manager calls when required commands are already
  installed, with guidance for archived Debian Jessie repositories.
- Made Fastfetch and its MOTD optional so they cannot abort the shell setup on
  legacy platforms.
- Added automatic workstation and server Fastfetch profiles, with an explicit
  override for future profile variants.
- Organized Fastfetch output into clear identity, session, performance,
  storage, network, and power sections.
- Added a clear error when a non-root user has no access to `sudo`.
- Updated installation documentation with browser copy buttons and matching
  guidance in both README files.
- Added community guidelines, structured issue forms, security reporting
  guidance, support information, and a privacy notice.
