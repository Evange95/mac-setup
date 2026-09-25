# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A single-shot, re-runnable macOS (Apple Silicon) developer bootstrap. `mac-setup.sh` is the entry point; the other files are data it consumes or copies into place. There is no build system and no test suite.

```bash
./mac-setup.sh                      # full run (prompts for sudo, SSH passphrase, git name/email if no setup.conf)
cp setup.conf.example setup.conf    # optional: pre-fill GIT_USER_NAME / GIT_USER_EMAIL (sourced by the script)
bash -n mac-setup.sh                # syntax check the script
brew bundle check --file=Brewfile   # see what in the Brewfile is not installed
```

`setup.conf` holds personal data and is gitignored.

## How the pieces fit

`mac-setup.sh` runs numbered sections (`# SECTION N:` headers; comments cross-reference them, e.g. "created in Section 9" — keep numbering consistent when adding/removing sections):

- **Packages**: CLI tools and GUI apps come from `Brewfile` via `brew bundle`. Language runtimes are *not* in the Brewfile except Go and pyenv/pipx — Rust (rustup), Node (Volta: node@24 + pnpm/typescript/tsx/claude-code as Volta globals), Bun, and Python 3.13 (pyenv) are installed by their own installers in Section 5.
- **Dotfiles are generated, not stored**: `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.gitignore_global` and `~/.ssh/config` are written from quoted heredocs (`<< 'ZSHRC'` etc.) inside `mac-setup.sh`. To change shell config, edit the heredoc — `$` inside is literal zsh, not expanded by bash. `.zshrc` is overwritten on every run (a timestamped backup is made); `.ssh/config` is only written if absent.
- **Copied config files**: `starship.toml` → `~/.config/starship.toml`; `iterm2-profile.json` → iTerm2 `DynamicProfiles/` (profile named "Developer"); `vscode-extensions.txt` is installed into both VS Code and Cursor (blank lines and `#` comments are skipped).
- **Git**: ~50 `git config --global` settings, delta as pager, aliases, and SSH commit/tag signing using `~/.ssh/id_ed25519.pub` with an `allowed_signers` file.
- **System**: security hardening (firewall, Touch ID sudo via `/etc/pam.d/sudo_local`, etc.), `defaults write` preferences, `~/Code/{personal,work,experiments,open-source}`, Colima start (vz + rosetta + virtiofs).
- **Verification**: Section 18's `VERIFY_TOOLS` array checks `--version` of key binaries — add new core tools there.

## Conventions to preserve

- **Idempotent**: every install is guarded (`command -v`, `[[ -d ... ]]`, `--skip-existing`). Re-running must be safe.
- **`set -e` is on**: steps that may fail without aborting the run use `|| log_warning "..."` or `|| true`. Use the `log_info/success/warning/error` helpers for output.
- **Migrations live in the script**: when a tool is replaced, the script removes the old one (e.g. Powerlevel10k → Starship, zsh-syntax-highlighting → fast-syntax-highlighting, `~/.p10k.zsh`, `~/.fzf.zsh`). Follow that pattern rather than leaving stale state.
- **Shell startup performance is a design goal** (see recent commits): no Oh My Zsh framework — `~/.oh-my-zsh/custom/plugins` is only a clone location and plugins are `source`d directly; PATH is set statically in `.zshenv` with no subprocesses; `fzf`, `zoxide` and `starship` init output is cached in `~/.cache/*.zsh` and regenerated only when the binary is newer; pyenv is lazy-loaded via stub functions; `compinit` dump is regenerated at most once per day. Don't add `eval "$(tool init)"` calls at startup — use the cache pattern.
- Generated dotfiles hardcode `/opt/homebrew` (Apple Silicon), even though Section 3 handles Intel for the current session.
