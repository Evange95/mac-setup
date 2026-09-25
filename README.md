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

Steps: `xcode homebrew packages languages shell iterm editors git ssh security macos dirs docker verify`

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

Because the dotfiles are symlinks, editing `~/.zshrc` edits the repo — commit it. Machine-specific settings go in `~/.zshrc.local`.

## Development

```bash
bats tests/
shellcheck -x setup.sh lib/*.sh steps/*.sh
```
