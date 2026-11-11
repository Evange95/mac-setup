# mac-setup

Re-runnable setup for a macOS developer machine (Node, Go, Python), with a `personal` and a `work` profile.

## Quick start

```bash
git clone git@github.com:Evange95/mac-setup.git ~/Code/personal/mac-setup
cd ~/Code/personal/mac-setup
cp setup.conf.example setup.conf   # set PROFILE, git name/email, optional work email
./setup.sh --dry-run               # check what will run
./setup.sh
```

On a company-managed Mac use `PROFILE="work"`: it skips admin-only security settings (usually owned by MDM) and installs `Brewfile.work` instead of `Brewfile.personal`. Homebrew itself needs admin rights for its first install — check with IT first.

## Nix

```bash
./setup.sh --nix      # or PACKAGE_MANAGER="nix" in setup.conf
```

Same steps, same profiles; only the `packages` step changes. It installs Nix if missing and activates the flake with nix-darwin (needs admin rights, so on a managed Mac stay on Homebrew):

- CLI tools come from nixpkgs instead of Homebrew. `nix/formulae.nix` says which package replaces each `brew` line of the Brewfiles.
- Apps (casks, App Store) still come from Homebrew, read from the same Brewfiles.
- `/nix` is excluded from Spotlight and Time Machine, and old generations are garbage-collected.

The first run creates `flake.lock`: commit it. Update with `nix flake update` and rerun.

Either way the step lists Homebrew packages that the repo does not declare. `BREW_CLEANUP="uninstall"` in `setup.conf` removes them; in Nix mode that includes the formulae now provided by nixpkgs.

## Options

| Flag | Effect |
| --- | --- |
| `--profile personal\|work` | overrides `PROFILE` from `setup.conf` |
| `--nix` | CLI packages from Nix (nix-darwin) instead of Homebrew |
| `--only a,b` | run only these steps (can force a step the profile skips) |
| `--skip a,b` | skip these steps |
| `--dry-run` | print profile and steps, run nothing |

Steps: `xcode homebrew packages languages shell iterm editors git ssh security macos dirs docker audit verify`

## What goes where

| Path | Installed to |
| --- | --- |
| `Brewfile`, `Brewfile.<profile>` | CLI tools and apps (the package list for Homebrew and for Nix) |
| `flake.nix`, `nix/` | nix-darwin configuration used by `--nix` |
| `config/mise/config.toml` | `~/.config/mise/config.toml` — node, go, python and their tooling |
| `dotfiles/zsh/*` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc` (symlinks) |
| `dotfiles/git/config` | `~/.config/git/config` (symlink); identity stays in `~/.gitconfig` |
| `dotfiles/git/ignore` | `~/.config/git/ignore` (copy) |
| `dotfiles/ssh/config` | `~/.ssh/config` (only if missing) |
| `config/starship.toml` | `~/.config/starship.toml` (symlink) |
| `config/iterm2-profile.json` | iTerm2 dynamic profile "Developer" (copy), set as default profile |

Because the dotfiles are symlinks, editing `~/.zshrc` edits the repo — commit it. Machine-specific settings go in `~/.zshrc.local`.

**iTerm2:** change the Developer profile in `config/iterm2-profile.json` and rerun `./setup.sh --only iterm`. Changes made in iTerm2's Settings to a dynamic profile are discarded on reload; to experiment, duplicate it first. Don't delete iTerm2's own "Default" profile. If iTerm2 is open, the step can't set the default profile — quit it and rerun.

## Development

```bash
bats tests/
shellcheck -x setup.sh lib/*.sh steps/*.sh scripts/*.sh
```

`./scripts/inventory.sh` writes a read-only report of what is installed and running on the Mac (packages, login items, memory per app) to `logs/`, to compare the machine with the repo.
