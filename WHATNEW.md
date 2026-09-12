# What's New

This file highlights user-facing changes. For the complete history, see the
[commit history](https://github.com/manix84/dotfiles_zsh/commits/main/).

## Unreleased

### Added

- Added default Linux Avahi installation, mDNS hostname resolution, and service startup.
- Added Homebrew bootstrap and persistent Bash/Zsh environment setup.

- Added automatic or explicit Bash/Zsh selection with `--shell`, `--bash`, and
  `--zsh` installer options.
- Added an Oh My Bash configuration using the Powerbash10k theme, plus
  shell-specific aliases and function extension files for Bash and Zsh.
- Replaced the Zsh Bullet Train theme with Powerlevel10k and aligned its prompt
  structure with the Bash Powerbash10k configuration where supported.
- Added shared, user-overridable Bash and Zsh theme defaults in `.sh_theme`.
- Added strict shared, shell-specific, and macOS-only deployment rules.
- Added non-destructive managed-block updates for existing `.bashrc` and
  `.bash_profile` files.

### Improved

- Reframed the project documentation around equal Bash and Zsh support and
  documented the shared, shell-specific, and platform-specific file model.
- Added copy-ready automatic, Bash, and Zsh installation commands to both
  README files.
- Added support for running the installer from an existing root shell on
  sudo-less systems such as ReadyNAS.
- Improved compatibility with the older Bash versions found on some NAS
  devices.
- Avoided unnecessary package-manager calls when required commands are already
  installed, with guidance for archived Debian Jessie repositories.
- Removed the unnecessary `jq` dependency so legacy systems do not need to
  access archived package repositories just to resolve a Fastfetch release.
- Made Fastfetch and its MOTD optional so they cannot abort the shell setup on
  legacy platforms.
- Skipped incompatible Fastfetch downloads on Debian Jessie and made existing
  shell-framework installations reusable on repeated installer runs.
- Aligned Oh My Bash and Oh My Zsh installation around validated shallow Git
  clones that never invoke upstream startup-file installers.
- Fixed early exit when Zsh was already the login shell and now activate the
  refreshed Oh My Zsh configuration immediately after interactive setup.
- Preserved interactive-terminal detection across log redirection so automatic
  Zsh activation works when installer output is recorded through `tee`.
- Added automatic workstation and server Fastfetch profiles, with an explicit
  override for future profile variants.
- Organized Fastfetch output into clear identity, session, performance,
  storage, network, and power sections.
- Added a clear error when a non-root user has no access to `sudo`.
- Updated installation documentation with browser copy buttons and matching
  guidance in both README files.
- Added community guidelines, structured issue forms, security reporting
  guidance, support information, and a privacy notice.
