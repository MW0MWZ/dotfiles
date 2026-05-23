# lib/optional.sh - end-of-bootstrap prompts: chsh to bash, install
# tmux/mosh/docker.

# Source install.sh for install_pkg / install_cask.
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/install.sh"

_opt_msg()  { printf '[bootstrap] %s\n' "$*"; }
_opt_ask()  {
    printf '[bootstrap] %s ' "$1" >&2
    REPLY=""
    if ! { IFS= read -r REPLY </dev/tty; } 2>/dev/null; then
        IFS= read -r REPLY 2>/dev/null || REPLY=""
    fi
}
_opt_confirm() {
    _opt_ask "$1 [y/N]"
    case "$REPLY" in [yY]|[yY][eE][sS]) return 0 ;; esac
    return 1
}

maybe_chsh() {
    local bash_path="$1"
    [ -x "$bash_path" ] || return 0

    # Login shell on this account, best-effort across systems.
    local current_shell=""
    if command -v getent >/dev/null 2>&1; then
        current_shell=$(getent passwd "${USER:-$(id -un 2>/dev/null)}" 2>/dev/null | cut -d: -f7)
    elif [ -r /etc/passwd ]; then
        current_shell=$(grep "^${USER:-$(id -un 2>/dev/null)}:" /etc/passwd | cut -d: -f7)
    fi

    if [ "$current_shell" = "$bash_path" ]; then
        _opt_msg "Login shell is already $bash_path -- skipping chsh."
        return 0
    fi

    _opt_msg "Your login shell is '$current_shell'; bash is at '$bash_path'."
    if ! _opt_confirm "Change login shell to $bash_path now?"; then
        _opt_msg "Skipping chsh. You can run it later: chsh -s $bash_path"
        return 0
    fi

    # /etc/shells must list bash_path or chsh refuses on most systems.
    if [ -r /etc/shells ] && ! grep -qxF "$bash_path" /etc/shells; then
        _opt_msg "Adding $bash_path to /etc/shells (requires sudo)."
        printf '%s\n' "$bash_path" | ${SUDO} tee -a /etc/shells >/dev/null || {
            _opt_msg "Failed to update /etc/shells. Run manually: echo '$bash_path' | sudo tee -a /etc/shells"
            return 1
        }
    fi

    if ! chsh -s "$bash_path"; then
        _opt_msg "chsh failed. Re-run manually: chsh -s $bash_path"
        return 1
    fi
    _opt_msg "Login shell changed. Open a new shell session for it to take effect."
}

_install_one() {
    local label="$1"; local cmd="$2"; local pkg="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        _opt_msg "$label already installed."
        return 0
    fi
    if ! _opt_confirm "Install $label?"; then
        _opt_msg "Skipping $label."
        return 0
    fi
    if install_pkg "$pkg"; then
        _opt_msg "$label installed."
    else
        _opt_msg "Failed to install $label automatically; install manually if you want it."
    fi
}

_offer_bash_completion() {
    # bash-completion is a sourced library, not a PATH binary -- detect
    # by checking the framework files instead of `command -v`.
    local f
    for f in \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/local/etc/profile.d/bash_completion.sh \
        /usr/share/bash-completion/bash_completion \
        /usr/local/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /opt/csw/etc/bash_completion
    do
        if [ -r "$f" ]; then
            _opt_msg "bash-completion already installed."
            return 0
        fi
    done
    if ! _opt_confirm "Install bash-completion (tab-completion for installed tools)?"; then
        _opt_msg "Skipping bash-completion."
        return 0
    fi
    case "$OS" in
        Darwin) install_pkg bash-completion@2 ;;   # needs bash 4+; pairs with the brew bash install
        *)      install_pkg bash-completion ;;
    esac && _opt_msg "bash-completion installed." \
         || _opt_msg "Failed to install bash-completion automatically."
}

offer_optional_tools() {
    _opt_msg "Optional tooling:"
    _install_one tmux tmux tmux
    _install_one mosh mosh mosh
    _install_one fzf  fzf  fzf
    _install_one direnv direnv direnv
    _offer_bash_completion

    # Docker is platform-specific: cask on macOS, native pkg on Linux.
    if command -v docker >/dev/null 2>&1; then
        _opt_msg "docker already installed."
        return 0
    fi
    if ! _opt_confirm "Install Docker?"; then
        _opt_msg "Skipping Docker."
        return 0
    fi
    case "$OS" in
        Darwin)
            if install_cask docker; then
                _opt_msg "Docker Desktop installed. Launch it once from /Applications/Docker.app."
            else
                _opt_msg "Docker install failed."
            fi ;;
        Linux)
            case ":$DISTRO_ID:$DISTRO_ID_LIKE:" in
                *:debian:*|*:ubuntu:*) install_pkg docker.io ;;
                *:fedora:*|*:rhel:*|*:centos:*) install_pkg docker ;;
                *:arch:*) install_pkg docker ;;
                *:suse:*|*:opensuse*:*) install_pkg docker ;;
                *) _opt_msg "Unknown Linux flavour; install docker manually." ;;
            esac ;;
        *) _opt_msg "Docker install on $OS not automated; install manually if you want it." ;;
    esac
}
