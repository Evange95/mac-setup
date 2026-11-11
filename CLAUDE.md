# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A re-runnable macOS (Apple Silicon) developer bootstrap with two profiles: `personal` and `work` (managed Mac, no admin-only changes). `setup.sh` is the entry point; everything else is data it installs, links or copies.

```bash
./setup.sh --dry-run                    # show profile and steps, run nothing
./setup.sh --profile work               # full run for a managed work Mac
./setup.sh --only git,shell             # re-apply selected steps
./setup.sh --nix                        # CLI packages from nix-darwin instead of Homebrew
./scripts/inventory.sh                  # read-only report of what the Mac has installed/running
bats tests/                             # all tests; single file: bats tests/cli.bats
bats tests/cli.bats -f "work profile"   # single test by name
shellcheck -x setup.sh lib/*.sh steps/*.sh scripts/*.sh
zsh -n dotfiles/zsh/zshrc
```

`setup.conf` (from `setup.conf.example`, gitignored) sets `PROFILE`, `PACKAGE_MANAGER`, git identities and Colima size. Every run logs to `logs/` (gitignored). CI (`.github/workflows/ci.yml`) runs shellcheck, zsh syntax, bats and validates the mise config.

## Architecture

- `lib/cli.sh` owns the step list (`ALL_STEPS`, canonical order), profiles and per-profile default skips (`profile_skips`: `work` skips `security`). `--only` can force a skipped step.
- Each step is `steps/<name>.sh` defining `step_<name>`; `setup.sh` sources and runs the selected ones. A test enforces this mapping, so adding a step means adding it to `ALL_STEPS` and creating the file.
- **Two package paths, one list**: `PACKAGE_MANAGER` (`brew` default, `nix` via `--nix`) only changes `steps/packages.sh`. The Brewfiles are the single package list: in Nix mode `nix/brewfile.nix` parses them (one entry per line, from column 0), `nix/formulae.nix` maps every `brew` formula to a nixpkgs package or `null` (stays in Homebrew), and `nix/darwin.nix` installs casks/App Store apps through nix-darwin's Homebrew module. Adding a `brew` line means adding it to `nix/formulae.nix` (a test and a Nix assertion enforce it). The flake is deliberately only the package layer: dotfile links, mise, git, macOS and security settings stay in the bash steps for both paths, so don't duplicate them in Nix. Machine values reach the flake as `MAC_SETUP_*` env vars (`--impure`). Evaluate without a Mac: `nix eval --impure .#darwinConfigurations.personal.system.drvPath`.
- `lib/probes.sh`: read-only security checks (`*_ok` functions). `steps/security.sh` applies a setting only when its probe fails and re-checks it afterwards (`_ensure`); `steps/audit.sh` reports all probes without sudo and runs in every profile. Prefer adding a probe over a blind `defaults write` — several macOS keys are silently ignored on current versions.
- `lib/common.sh`: logging, `link_file` (symlink with backup of existing files), `copy_file`, `try` (run and warn instead of aborting), `load_session_env`.
- **Linked vs copied**: dotfiles are symlinked from `dotfiles/` so edits in `~` land in the repo — except files other tools write to, which are copied: `~/.config/git/ignore` (Claude Code appends to it), iTerm2 dynamic profile (`steps/iterm.sh` also makes it the default profile, only while iTerm2 is not running), `~/.ssh/config` (copied only if absent).
- **Git config is split**: shared settings in `dotfiles/git/config` → `~/.config/git/config`; identity, signing key and `includeIf` per-directory identities (`GIT_WORK_EMAIL` → `~/Code/work/`, `GIT_PERSONAL_EMAIL` → `~/Code/personal/`) are written into `~/.gitconfig` by `steps/git.sh`/`steps/ssh.sh`. Never `git config --global` a shared setting — it would shadow the managed file (the git step migrates such keys out).
- **Toolchains come from mise, not Homebrew**: node, pnpm, bun, go, python, uv, ruff, golangci-lint, Go dev tools and npm/pipx globals are declared in `config/mise/config.toml` (→ `~/.config/mise/config.toml`). Homebrew (`Brewfile` + `Brewfile.<profile>`) is for CLI utilities and apps. Rust (a mise tool driving rustup, `config/mise/personal.toml`) and LaTeX (`mactex-no-gui`, `/Library/TeX/texbin` on the static PATH) are personal-only. Claude Code uses the native installer.

## Conventions

- `setup.sh` runs under macOS `/bin/bash` 3.2: no associative arrays, `mapfile`, `${var,,}`.
- `set -e` is on: anything that may legitimately fail (sudo on managed Macs, optional installs) goes through `try` or `|| log_warning`.
- Idempotent: every install is guarded; re-running must be safe. When a tool is replaced, the step that owns it removes or warns about the old one (Oh My Zsh, Powerlevel10k, Volta/pyenv, replaced apps and VS Code extensions).
- Shell startup speed is a design goal (~0.1s): no framework, static PATH in `zshenv` (includes mise shims for non-interactive shells), tool init scripts cached via `_cached_init` in `zshrc` and regenerated when the binary's resolved path changes (works for Homebrew and for Nix store paths, whose mtime is constant). Tools are looked up on the PATH, never under `$HOMEBREW_PREFIX/bin`, since they may come from Nix; only the zsh plugins are always Homebrew. Don't add raw `eval "$(tool init)"` at startup.
- Machine-specific shell config belongs in `~/.zshrc.local` (not versioned), not in `dotfiles/zsh/zshrc`.
