#!/bin/bash
set -eu
REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-system-setup.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

# Load only function definitions; never execute the installer or redirect logging.
eval "$(sed -n '/^configure_mdns_resolution() {/,/^download_file() {/p' "$REPOSITORY_ROOT/auto-install/setup.sh" | sed '$d')"
run_as_root() { "$@"; }
config="$TEST_ROOT/nsswitch.conf"
printf 'passwd: files\nhosts: files resolve [!UNAVAIL=return] dns # keep\n' > "$config"
cp "$config" "$TEST_ROOT/original"
configure_mdns_resolution "$config"
grep -Fqx 'hosts: files resolve [!UNAVAIL=return] mdns4_minimal [NOTFOUND=return] dns # keep' "$config"
cmp "$TEST_ROOT/original" "$config.dotfiles-backup"
cp "$config" "$TEST_ROOT/once"
configure_mdns_resolution "$config"
cmp "$config" "$TEST_ROOT/once"
cmp "$TEST_ROOT/original" "$config.dotfiles-backup"
printf 'hosts: files mdns_minimal [NOTFOUND=return] dns\n' > "$config"
cp "$config" "$TEST_ROOT/existing"
configure_mdns_resolution "$config"
cmp "$config" "$TEST_ROOT/existing"
printf 'passwd: files\n' > "$config"
if configure_mdns_resolution "$config"; then
  echo 'Unexpected success without hosts entry' >&2
  exit 1
fi

# macOS must never invoke native Avahi package installation.
PLATFORM_OS=Darwin
install_package() { echo 'Unexpected package installation' >&2; exit 1; }
install_avahi

# Exercise Linux package selection, service activation, and failure propagation.
(
  PLATFORM_OS=Linux
  package_calls=""
  service_calls=""
  command() {
    case "$*" in
      '-v apt'|'-v rc-update') return 0 ;;
      '-v apk'|'-v systemctl') return 1 ;;
      *) builtin command "$@" ;;
    esac
  }
  install_package() { package_calls="$*"; }
  configure_mdns_resolution() { return 0; }
  run_as_root() { service_calls="$service_calls;$*"; }
  install_avahi
  [[ "$package_calls" == 'avahi-daemon avahi-utils libnss-mdns' ]]
  [[ "$service_calls" == *'rc-update add avahi-daemon default;rc-service avahi-daemon start' ]]
  install_package() { return 1; }
  if install_avahi; then
    echo 'Package failure was ignored' >&2
    exit 1
  fi
)

# Reuse a PATH-visible Homebrew and load its environment without downloads.
mkdir -p "$TEST_ROOT/bin"
printf '#!/bin/sh\n[ "$1" = shellenv ] || exit 1\necho "export DOTFILES_TEST_BREW=loaded"\n' > "$TEST_ROOT/bin/brew"
chmod +x "$TEST_ROOT/bin/brew"
PATH="$TEST_ROOT/bin:$PATH"
install_homebrew
[[ "$DOTFILES_TEST_BREW" == loaded ]]
unset DOTFILES_TEST_BREW
source "$REPOSITORY_ROOT/.sh_homebrew"
[[ "$DOTFILES_TEST_BREW" == loaded ]]

# Verify both installers append the activation once and retain user content.
for installer in setup.sh setup-user.sh; do
  eval "$(sed -n '/^configure_homebrew_shell() {/,/^record_install() {/p' "$REPOSITORY_ROOT/auto-install/$installer" | sed '$d')"
  for TARGET_SHELL in bash zsh; do
    config="$TEST_ROOT/.${TARGET_SHELL}rc"
    printf '# existing user configuration\n' > "$config"
    (HOME="$TEST_ROOT"; configure_homebrew_shell; configure_homebrew_shell)
    [[ $(grep -c sh_homebrew "$config") == 1 ]]
    grep -Fqx '# existing user configuration' "$config"
  done
done
echo "System setup and Homebrew environment tests passed."
