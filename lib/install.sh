# lib/install.sh - package install helpers shared between update.sh and
# lib/optional.sh. Requires detect_all to have populated OS/SUDO.

install_pkg() {
    local pkg="$1"
    case "$OS" in
        Linux)
            case ":$DISTRO_ID:$DISTRO_ID_LIKE:" in
                *:debian:*|*:ubuntu:*)
                    ${SUDO} apt-get update && ${SUDO} apt-get install -y "$pkg" ;;
                *:rhel:*|*:centos:*|*:rocky:*|*:almalinux:*)
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
                printf 'install_pkg: brew not found. Install Homebrew first.\n' >&2
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

install_cask() {
    # macOS-only: install a Homebrew cask (GUI app).
    local cask="$1"
    if [ "$OS" != "Darwin" ]; then
        printf 'install_cask: only supported on Darwin\n' >&2
        return 1
    fi
    if ! command -v brew >/dev/null 2>&1; then
        printf 'install_cask: brew not found.\n' >&2
        return 1
    fi
    brew install --cask "$cask"
}
