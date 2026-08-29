# Contributing

Thanks for helping improve this project.

## Before opening an issue

- Check existing issues for the same problem or suggestion.
- Review the installer and both README files for current behavior.
- Remove credentials, private hostnames, IP addresses, usernames, and personal
  paths from logs and examples.

Use the relevant issue form and include the operating system, architecture,
shell, package manager, command used, and the smallest useful error excerpt.

## Pull requests

1. Create a focused branch from `main`.
2. Keep changes portable across supported macOS and Linux environments.
3. Use `bash` for the installer and quote shell expansions safely.
4. Run `bash -n auto-install/setup.sh auto-install/setup-user.sh`.
5. Run `git diff --check`.
6. Update both installation README files when their shared guidance changes.
7. Update `WHATNEW.md` for user-facing changes.

By contributing, you agree that your contribution is licensed under the
project's [MIT License](../LICENSE).
