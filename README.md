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

1. Detects the OS, current shell, and whether bash is reachable. If
   bash isn't installed, tries to install it via the system package
   manager before giving up (handles Alpine / minimal images).
2. Re-execs under bash once a working `bash` is located. Re-exec also
   fires when the current shell *is* bash but in POSIX mode (e.g.
   `/bin/sh -> bash` on macOS and some Fedora installs), since
   later lib helpers use process substitution that POSIX mode rejects.
3. Verifies `git`, `stow`, and `curl|wget` are installed; offers to
   install missing ones via the system package manager.
4. Clones (or pulls) the repo to `$DOTFILES_DIR` (default
   `~/.dotfiles`).
5. For each stow package (`bash`, `tmux`), walks the target tree and
   moves any pre-existing real file aside to `<file>.bak.<timestamp>`
   before symlinking. The walker is tree-aware: if a directory in
   `$HOME` is already a symlink into the repo, it skips that subtree
   instead of recursing through the symlink — so re-runs of bootstrap
   (or `update.sh`) never corrupt the repo by `mv`-ing through a
   folded directory.
6. Prompts to change the login shell to bash (`chsh`). Skipped when
   the current login shell already resolves to the same binary
   (`/bin/bash` and `/usr/bin/bash` on usrmerge distros are the same
   file via symlink). Failure of `chsh` itself (e.g. PAM password
   prompt with no controlling tty) prints a manual-fix hint and
   continues — it never aborts bootstrap.
7. Prompts to install `tmux`, `mosh`, `fzf`, `direnv`, `bash-completion`,
   and Docker. Each is independent; skip what you don't want.

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
│   ├── stow.sh          tree-aware backup-on-conflict, then stow each package
│   ├── optional.sh      chsh prompt + tmux/mosh/fzf/direnv/bash-completion/docker installer
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

## tmux defaults worth flagging

- **Mouse mode is off by default.** macOS Terminal.app's xterm-mouse
  handoff to tmux drops clicks and feeds scroll events to the wrong
  pane. If you want it on per-session: `prefix : set mouse on`.
- **Copy uses OSC 52**, not platform clipboard tools. `prefix [` enters
  copy-mode, motion keys + `y` copies, and tmux emits an escape
  sequence the outer terminal decodes into your local clipboard. Works
  identically whether tmux is local or on a remote you `ssh`/`mosh`'d
  into. Each terminal needs to be told once to honour OSC 52:
    - **iTerm2:** Preferences → General → Selection →
      "Applications in terminal may access clipboard"
    - **Terminal.app:** `defaults write com.apple.Terminal AllowClipboardAccess -bool true`
    - **kitty, foot, wezterm, Alacritty:** on by default

## Supported platforms

| Platform                | Bootstrap | OS update routine               |
| ----------------------- | --------- | ------------------------------- |
| macOS (Intel + Apple)   | yes       | `lib/os/darwin.sh` (Homebrew + softwareupdate) |
| Debian / Ubuntu         | yes       | `lib/os/linux-debian.sh`        |
| RHEL / CentOS / Rocky   | yes       | `lib/os/linux-rhel.sh`          |
| Fedora                  | yes       | `lib/os/linux-fedora.sh`        |
| Arch                    | yes       | `lib/os/linux-arch.sh`          |
| openSUSE / SLES         | yes       | `lib/os/linux-suse.sh`          |
| Alpine                  | yes       | `lib/os/linux-alpine.sh`        |
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
