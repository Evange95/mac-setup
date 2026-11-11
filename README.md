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

## Options

| Flag | Effect |
| --- | --- |
| `--profile personal\|work` | overrides `PROFILE` from `setup.conf` |
| `--only a,b` | run only these steps (can force a step the profile skips) |
| `--skip a,b` | skip these steps |
| `--dry-run` | print profile and steps, run nothing |

Steps: `xcode homebrew packages languages shell iterm editors git ssh security macos dirs docker audit verify`

## What goes where

| Path | Installed to |
| --- | --- |
| `Brewfile`, `Brewfile.<profile>` | Homebrew CLI tools and apps |
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

## Running containers on another machine

Set `HOMELAB_DOCKER_HOST="ssh://user@host"` in `setup.conf` and run `./setup.sh --only docker`. Then `dhome` points `docker` at that machine and stops the local Colima VM (which otherwise keeps its memory for as long as it runs); `dlocal` starts Colima and switches back. Containers started this way run on the remote machine: bind mounts refer to its filesystem, not the Mac's, and published ports are reached at its address.

## Cleaning up without reinstalling macOS

```bash
./scripts/cleanup.sh                     # report only: shows every command it would run
./scripts/cleanup.sh --apply             # do it
./scripts/cleanup.sh --apply --volumes   # also delete unused Docker volumes (data loss)
```

It removes Homebrew packages the Brewfiles no longer declare, toolchain versions no mise config uses, package caches and unused Docker images/build cache. Apps installed by hand, login items and background services are listed for review, never removed. To keep something it wants to remove, add it to a Brewfile first.

`./scripts/inventory.sh` writes a read-only report of what is installed and running on the Mac (packages, login items, memory per app) to `logs/`, to compare the machine with the repo.
