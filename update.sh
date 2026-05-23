#!/usr/bin/env bash
# update.sh - keep this box current.
#
# Two jobs:
#   1. git pull the dotfiles repo and re-run stow so newly-added files
#      get linked into $HOME.
#   2. Run the platform's package manager to update system packages
#      (so bash / tmux / mosh / docker themselves stay current).
#
# Flags:
#   --no-sync   skip dotfile sync (OS package update only)
#   --no-pkgs   skip OS package update (dotfile sync only)
#   --help      show usage

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

DO_SYNC=1
DO_PKGS=1
for arg in "$@"; do
    case "$arg" in
        --no-sync) DO_SYNC=0 ;;
        --no-pkgs) DO_PKGS=0 ;;
        -h|--help)
            sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) printf 'update.sh: unknown flag %s\n' "$arg" >&2; exit 2 ;;
    esac
done

msg() { printf '[update] %s\n' "$*"; }
err() { printf '[update] error: %s\n' "$*" >&2; }

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    err "$DOTFILES_DIR is not a git checkout. Run bootstrap.sh first."
    exit 1
fi

# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/detect.sh"
# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/install.sh"
# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/stow.sh"

detect_all

# ---- 1. dotfile sync -------------------------------------------------
if [ "$DO_SYNC" = "1" ]; then
    msg "Syncing dotfiles repo at $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" fetch --quiet
    if ! git -C "$DOTFILES_DIR" pull --ff-only; then
        err "git pull --ff-only failed (non-fast-forward or local changes). Resolve manually."
        err "Run with --no-sync to skip the dotfile sync step."
        exit 1
    fi
    # Re-stow — idempotent. Picks up new files, leaves existing links alone.
    stow_packages "$DOTFILES_DIR" "$HOME" bash tmux
fi

# ---- 2. OS package update -------------------------------------------
if [ "$DO_PKGS" = "1" ]; then
    msg "Updating system packages for platform '$PLATFORM'"
    os_script="$DOTFILES_DIR/lib/os/$PLATFORM.sh"
    if [ ! -r "$os_script" ]; then
        err "No update routine for platform '$PLATFORM' (expected $os_script)."
        err "Add one, or run with --no-pkgs."
        exit 1
    fi
    # shellcheck disable=SC1090
    . "$os_script"
    if ! declare -f os_update >/dev/null; then
        err "$os_script must define os_update()."
        exit 1
    fi
    os_update
fi

msg "Done."
