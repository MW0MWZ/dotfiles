# dotfiles

Cross-platform bash environment plus an OS-package updater. Lives in
`~/.dotfiles`, gets symlinked into `$HOME` via GNU stow, kept current
with `update.sh`.

Scope is deliberately narrow: bash, tmux, mosh, docker. No editor, no
window manager, no language toolchains.

## Quick start

```sh
# One-liner, after you've got curl OR wget:
curl -fsSL https://raw.githubusercontent.com/MW0MWZ/dotfiles/main/bootstrap.sh | sh

# Or run from a local clone:
git clone https://github.com/MW0MWZ/dotfiles ~/.dotfiles
sh ~/.dotfiles/bootstrap.sh
```

Override defaults via env vars:

```sh
DOTFILES_REPO=https://example.com/me/dotfiles.git \
DOTFILES_DIR="$HOME/.config/dotfiles" \
sh bootstrap.sh
```

## What bootstrap.sh does

1. Detects the OS, current shell, and whether bash is reachable.
2. Re-execs under bash once a working `bash` is located (POSIX-sh in the
   early phase so it runs from sh/dash/ksh/zsh/old-bash).
3. Verifies `git`, `stow`, and `curl|wget` are installed; offers to
   install missing ones via the system package manager.
4. Clones (or pulls) the repo to `$DOTFILES_DIR` (default
   `~/.dotfiles`).
5. For each stow package (`bash`, `tmux`), backs up any pre-existing
   real file at the target to `<file>.bak.<timestamp>` and then
   symlinks the repo copy into `$HOME`.
6. Prompts to change the login shell to bash (`chsh`).
7. Prompts to install `tmux`, `mosh`, and Docker.

## What update.sh does

```sh
~/.dotfiles/update.sh          # both: pull + re-stow + OS package update
~/.dotfiles/update.sh --no-sync   # OS packages only
~/.dotfiles/update.sh --no-pkgs   # dotfile sync only
```

`git pull --ff-only` keeps `~/.dotfiles` current and re-stows
idempotently (newly-added files get linked, existing links left alone).
Then it dispatches to `lib/os/<platform>.sh` for native package updates.

Symlinks make the sync free: editing a file in `~/.dotfiles/bash/...`
takes effect immediately. There is no version marker — `git` is the
source of truth.

## Layout

```
~/.dotfiles/
├── bootstrap.sh         POSIX sh, first-run setup
├── update.sh            bash, OS pkg update + dotfile re-stow
├── install_stow.sh      userspace stow builder (Solaris 10 fallback etc)
├── lib/
│   ├── detect.sh        OS / shell / bash-version probes
│   ├── install.sh       per-OS package install helpers
│   ├── stow.sh          back up conflicts, then stow each package
│   ├── optional.sh      chsh prompt + tmux/mosh/docker installer
│   └── os/<platform>.sh per-platform package update routine
├── bash/                stow package: $HOME bash environment
│   ├── .bash_profile
│   ├── .profile
│   ├── .bashrc
│   ├── .inputrc
│   ├── .profile.d/      sourced by .profile (PATH, EDITOR, etc)
│   └── .bashrc.d/       sourced by .bashrc (interactive: aliases, funcs, prompt)
└── tmux/                stow package: .tmux.conf
```

## Local overrides

Files the dotfiles never touch but the rc files source if present:

| file               | sourced from   | purpose                              |
| ------------------ | -------------- | ------------------------------------ |
| `~/.profile.local` | `~/.profile`   | per-host env vars / PATH tweaks       |
| `~/.bashrc.local`  | `~/.bashrc`    | per-host aliases / functions / etc    |

Edit these freely. They never get overwritten by `update.sh`.

## Supported platforms

| Platform                | Bootstrap | OS update routine               |
| ----------------------- | --------- | ------------------------------- |
| macOS (Intel + Apple)   | yes       | `lib/os/darwin.sh` (Homebrew + softwareupdate) |
| Debian / Ubuntu         | yes       | `lib/os/linux-debian.sh`        |
| RHEL / CentOS / Rocky   | yes       | `lib/os/linux-rhel.sh`          |
| Fedora                  | yes       | `lib/os/linux-fedora.sh`        |
| Arch                    | yes       | `lib/os/linux-arch.sh`          |
| openSUSE / SLES         | yes       | `lib/os/linux-suse.sh`          |
| FreeBSD                 | yes       | `lib/os/freebsd.sh`             |
| OpenBSD                 | yes       | `lib/os/openbsd.sh`             |
| Solaris 10 / 11         | yes       | `lib/os/sunos.sh` (OpenCSW pkgutil) |

bash 3.2 is the lowest-common-denominator target (Apple's `/bin/bash`,
Solaris 10). Features that need newer bash are feature-gated on
`BASH_VERSINFO`.

## Bash 3.2 quirks worth knowing about

- The recursive glob `~/.bashrc.d/**/*.bash` expands as `*/*.bash` on
  bash without `globstar`. Drop-ins live exactly one level deep so the
  same pattern works on both.
- `local -A` (associative arrays) and `${var,,}` (lowercase expansion)
  are bash 4+. Don't reach for them in `.bashrc.d/*.bash` without a
  version guard.

## Userspace stow

If your package manager can't supply stow (looking at you, Solaris 10),
bootstrap.sh will offer to run `install_stow.sh`, which builds stow
into `~/.local` from the GNU FTP source tarball. Requires `perl`,
`make`, `tar`, and `curl|wget`.
