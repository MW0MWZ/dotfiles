#!/bin/sh
# bootstrap.sh - first-run setup for this dotfiles repo.
#
# Runnable in any POSIX shell (sh / dash / ksh / zsh / bash). The early
# section is POSIX-compliant; once a working bash is located we re-exec
# under it for the rest of the work.
#
# Usage:
#   sh bootstrap.sh                          # from a local clone
#   curl -fsSL <url>/bootstrap.sh | sh       # one-liner install
#
# Env overrides:
#   DOTFILES_REPO   git URL to clone (default: see DOTFILES_REPO_DEFAULT below)
#   DOTFILES_DIR    where to clone to (default: $HOME/.dotfiles)

set -eu

DOTFILES_REPO_DEFAULT="https://github.com/MW0MWZ/dotfiles.git"
DOTFILES_REPO="${DOTFILES_REPO:-$DOTFILES_REPO_DEFAULT}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

msg() { printf '[bootstrap] %s\n' "$*"; }
err() { printf '[bootstrap] error: %s\n' "$*" >&2; }

ask() {
    # ask "prompt" -> sets REPLY. Prefer /dev/tty (so piped-stdin doesn't
    # silently feed our prompts), but fall back to stdin silently when
    # /dev/tty isn't usable (e.g. docker run without -t).
    printf '[bootstrap] %s ' "$1" >&2
    REPLY=""
    if ! { IFS= read -r REPLY </dev/tty; } 2>/dev/null; then
        IFS= read -r REPLY 2>/dev/null || REPLY=""
    fi
}
confirm() {
    ask "$1 [y/N]"
    case "$REPLY" in [yY]|[yY][eE][sS]) return 0 ;; esac
    return 1
}

# ----------------------------------------------------------------------
# Piped-mode detection: when run via `curl ... | sh`, $0 is not a usable
# script path. Clone first, then re-exec the bootstrap script from the
# clone so we have lib/ available.
# ----------------------------------------------------------------------
case "$0" in
    sh|-sh|bash|-bash|dash|-dash|ksh|-ksh|zsh|-zsh)
        PIPED=1 ;;
    *)
        if [ -r "$0" ]; then PIPED=0; else PIPED=1; fi ;;
esac

# ----------------------------------------------------------------------
# OS detection (just enough to print install hints if a dep is missing)
# ----------------------------------------------------------------------
OS=$(uname -s)
ARCH=$(uname -m)
DISTRO_ID=""
DISTRO_ID_LIKE=""
case "$OS" in
    Linux)
        if [ -r /etc/os-release ]; then
            # shellcheck disable=SC1091
            . /etc/os-release
            DISTRO_ID="${ID:-linux}"
            DISTRO_ID_LIKE="${ID_LIKE:-$DISTRO_ID}"
        fi
        ;;
esac

if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# ----------------------------------------------------------------------
# Per-OS package install. Used to bring git / stow / curl into place
# before we have lib/ available. Mirrors install logic in lib/install.sh.
# ----------------------------------------------------------------------
install_pkg() {
    pkg="$1"
    case "$OS" in
        Linux)
            case ":$DISTRO_ID:$DISTRO_ID_LIKE:" in
                *:debian:*|*:ubuntu:*)
                    ${SUDO} apt-get update && ${SUDO} apt-get install -y "$pkg" ;;
                *:rhel:*|*:centos:*)
                    ${SUDO} yum install -y "$pkg" ;;
                *:fedora:*)
                    ${SUDO} dnf install -y "$pkg" ;;
                *:arch:*)
                    ${SUDO} pacman -S --noconfirm --needed "$pkg" ;;
                *:suse:*|*:opensuse*:*|*:sles:*)
                    ${SUDO} zypper install -y "$pkg" ;;
                *:alpine:*)
                    ${SUDO} apk add --no-cache "$pkg" ;;
                *)
                    return 1 ;;
            esac ;;
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                err "Homebrew not found. Install it and re-run:"
                err '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                return 1
            fi
            brew install "$pkg" ;;
        FreeBSD) ${SUDO} pkg install -y "$pkg" ;;
        OpenBSD) ${SUDO} pkg_add -I "$pkg" ;;
        SunOS)
            if command -v pkgutil >/dev/null 2>&1; then
                ${SUDO} /opt/csw/bin/pkgutil -y -i "$pkg"
            elif command -v pkg >/dev/null 2>&1; then
                ${SUDO} pkg install --accept "$pkg"
            else
                return 1
            fi ;;
        *) return 1 ;;
    esac
}

print_install_hint() {
    pkg="$1"
    err "Could not auto-install '$pkg'. Try one of:"
    case "$OS" in
        Linux)
            err "  Debian/Ubuntu:  ${SUDO} apt install $pkg"
            err "  RHEL/CentOS:    ${SUDO} yum install $pkg"
            err "  Fedora:         ${SUDO} dnf install $pkg"
            err "  Arch:           ${SUDO} pacman -S $pkg"
            err "  openSUSE/SLES:  ${SUDO} zypper install $pkg"
            err "  Alpine:         ${SUDO} apk add $pkg" ;;
        Darwin)  err "  brew install $pkg" ;;
        FreeBSD) err "  ${SUDO} pkg install $pkg" ;;
        OpenBSD) err "  ${SUDO} pkg_add $pkg" ;;
        SunOS)   err "  pkgutil -i $pkg   (Solaris 10 w/ OpenCSW)"
                 err "  ${SUDO} pkg install $pkg   (Solaris 11)" ;;
        *)       err "  Use your platform's package manager." ;;
    esac
}

require_or_install() {
    cmd="$1"
    pkg="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then return 0; fi
    msg "$cmd not found; attempting to install package '$pkg'..."
    if install_pkg "$pkg" && command -v "$cmd" >/dev/null 2>&1; then
        msg "$cmd installed."
        return 0
    fi
    print_install_hint "$pkg"
    return 1
}

# ----------------------------------------------------------------------
# In piped mode, we need git available now (to clone the repo so we can
# source lib/ helpers from it), then we re-exec the bootstrap script
# from the clone.
# ----------------------------------------------------------------------
if [ "$PIPED" = "1" ]; then
    msg "Detected piped install mode."
    require_or_install git || exit 1
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        msg "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        msg "Repo already present at $DOTFILES_DIR"
    fi
    export DOTFILES_REPO DOTFILES_DIR
    msg "Re-executing bootstrap from $DOTFILES_DIR/bootstrap.sh"
    exec sh "$DOTFILES_DIR/bootstrap.sh" "$@"
fi

# ----------------------------------------------------------------------
# Find a working bash and re-exec under it. Below this point we want
# bash features (arrays, [[, BASH_VERSINFO).
# ----------------------------------------------------------------------
find_bash() {
    for candidate in \
        /opt/homebrew/bin/bash \
        /usr/local/bin/bash \
        /opt/csw/bin/bash \
        /usr/bin/bash \
        /bin/bash
    do
        [ -x "$candidate" ] && { echo "$candidate"; return 0; }
    done
    if command -v bash >/dev/null 2>&1; then command -v bash; return 0; fi
    return 1
}

print_bash_install_help() {
    err "bash is required but was not found and auto-install failed."
    case "$OS" in
        Linux)   err "Install with your package manager (apt/dnf/yum/pacman/zypper/apk install bash)." ;;
        Darwin)  err "macOS ships /bin/bash; if missing, run: xcode-select --install" ;;
        FreeBSD) err "${SUDO} pkg install bash" ;;
        OpenBSD) err "${SUDO} pkg_add bash" ;;
        SunOS)   err "Solaris 10: pkgadd OpenCSW then pkgutil -i bash"
                 err "Solaris 11: ${SUDO} pkg install bash" ;;
        *)       err "Use your platform's package manager." ;;
    esac
}

# Re-exec into bash if we are not already running under bash *in
# non-POSIX mode*. The latter check matters on macOS / Solaris / some
# Fedora setups where /bin/sh is bash invoked as sh: BASH_VERSION is
# set but bash runs in POSIX mode and rejects process substitution
# (used in lib/stow.sh).
_need_reexec=0
if [ -z "${BASH_VERSION:-}" ]; then
    _need_reexec=1
elif [ -n "${POSIXLY_CORRECT:-}" ]; then
    _need_reexec=1
else
    # set -o is POSIX; we look for "posix on" which only bash emits.
    _posix=$(set -o 2>/dev/null | awk '$1=="posix"{print $NF}')
    [ "$_posix" = "on" ] && _need_reexec=1
fi

if [ "$_need_reexec" = "1" ]; then
    BASH_PATH=""
    if ! BASH_PATH=$(find_bash); then
        msg "bash not found; attempting to install it via the system package manager..."
        install_pkg bash || msg "auto-install of bash failed."
        BASH_PATH=$(find_bash) || BASH_PATH=""
    fi

    if [ -z "$BASH_PATH" ]; then
        print_bash_install_help
        exit 1
    fi

    msg "Re-executing under $BASH_PATH"
    export DOTFILES_REPO DOTFILES_DIR OS ARCH DISTRO_ID DISTRO_ID_LIKE SUDO
    exec "$BASH_PATH" "$0" "$@"
fi

# ====================================================================
# From here on we are running under bash.
# ====================================================================

set -o pipefail 2>/dev/null || true

BASH_MAJOR="${BASH_VERSINFO[0]}"
if [ "$BASH_MAJOR" -lt 4 ]; then
    msg "warning: bash $BASH_VERSION detected (pre-4). Newer features in rc files will fall back to 3.2-safe paths."
fi

# ---- ensure git / curl|wget / stow are present ----------------------
require_or_install git || exit 1

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    require_or_install curl || exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
    if ! install_pkg stow; then
        msg "stow not available via package manager."
        msg "After the repo is cloned you can build it userspace with:"
        msg "  $DOTFILES_DIR/install_stow.sh"
    fi
fi

# ---- clone / update repo --------------------------------------------
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
if [ -d "$DOTFILES_DIR/.git" ]; then
    msg "Repo already cloned at $DOTFILES_DIR -- pulling latest"
    git -C "$DOTFILES_DIR" pull --ff-only || msg "Pull failed; continuing with existing checkout."
else
    msg "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# If we ran bootstrap.sh from a checkout that isn't $DOTFILES_DIR, point
# users at the canonical location so update.sh works from one place.
if [ "$SCRIPT_PATH" != "$DOTFILES_DIR/bootstrap.sh" ] && [ -f "$DOTFILES_DIR/bootstrap.sh" ]; then
    msg "Bootstrap was run from $SCRIPT_PATH; canonical copy lives at $DOTFILES_DIR/bootstrap.sh."
fi

# ---- stow userspace fallback if still missing -----------------------
if ! command -v stow >/dev/null 2>&1; then
    if [ -x "$DOTFILES_DIR/install_stow.sh" ] && confirm "Build stow from source into ~/.local?"; then
        "$DOTFILES_DIR/install_stow.sh"
        PATH="$HOME/.local/bin:$PATH"
    fi
fi
if ! command -v stow >/dev/null 2>&1; then
    err "stow is still missing. Install it and re-run."
    exit 1
fi

# ---- source helpers --------------------------------------------------
# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/detect.sh"
# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/stow.sh"
# shellcheck disable=SC1091
. "$DOTFILES_DIR/lib/optional.sh"

detect_all

# ---- stow each package ----------------------------------------------
stow_packages "$DOTFILES_DIR" "$HOME" bash tmux

# ---- chsh prompt -----------------------------------------------------
# $BASH is whatever path was used to invoke us, which on some distros
# (Fedora's /bin/sh -> bash, busybox-ish layouts) is not the canonical
# bash binary path. Resolve to a real bash binary before offering it
# to chsh.
RESOLVED_BASH=""
for cand in \
    /opt/homebrew/bin/bash \
    /usr/local/bin/bash \
    /opt/csw/bin/bash \
    /usr/bin/bash \
    /bin/bash
do
    if [ -x "$cand" ]; then RESOLVED_BASH="$cand"; break; fi
done
if [ -z "$RESOLVED_BASH" ]; then
    RESOLVED_BASH=$(command -v bash 2>/dev/null || echo "$BASH")
fi
# Both of these are "nice to have, don't kill the bootstrap" steps.
# Belt-and-suspenders against set -e: the functions are written to
# return 0 on routine failures, but a stray non-zero from a nested
# call shouldn't take the whole bootstrap down.
maybe_chsh "$RESOLVED_BASH" || true

# ---- optional tools --------------------------------------------------
offer_optional_tools || true

msg "Done. Start a new shell, or: exec \"$RESOLVED_BASH\" -l"
