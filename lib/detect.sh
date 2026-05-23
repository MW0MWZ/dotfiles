# lib/detect.sh - canonical host detection, sourced by bootstrap.sh and update.sh.
#
# Calling detect_all populates these globals:
#   OS              uname -s (Linux | Darwin | FreeBSD | OpenBSD | SunOS | ...)
#   ARCH            uname -m
#   DISTRO_ID       /etc/os-release ID on Linux, e.g. "ubuntu", "fedora"
#   DISTRO_ID_LIKE  /etc/os-release ID_LIKE on Linux
#   DISTRO_VERSION  /etc/os-release VERSION_ID on Linux, sw_vers on Darwin, uname -r elsewhere
#   PLATFORM        bucket used to dispatch lib/os/<platform>.sh
#   IS_VM           "yes" / "no" / "unknown"
#   SUDO            "sudo" / "" depending on uid
#   BASH_MAJOR      first component of BASH_VERSINFO (only set when running under bash)

detect_os() {
    OS=$(uname -s)
    ARCH=$(uname -m)
}

detect_distro() {
    DISTRO_ID=""
    DISTRO_ID_LIKE=""
    DISTRO_VERSION=""
    case "$OS" in
        Linux)
            if [ -r /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                DISTRO_ID="${ID:-linux}"
                DISTRO_ID_LIKE="${ID_LIKE:-$DISTRO_ID}"
                DISTRO_VERSION="${VERSION_ID:-}"
            else
                DISTRO_ID="linux"
                DISTRO_ID_LIKE="linux"
                DISTRO_VERSION=$(uname -r)
            fi
            ;;
        Darwin)
            if command -v sw_vers >/dev/null 2>&1; then
                DISTRO_ID="macos"
                DISTRO_ID_LIKE="darwin"
                DISTRO_VERSION=$(sw_vers -productVersion)
            fi
            ;;
        FreeBSD|OpenBSD|SunOS)
            DISTRO_ID=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
            DISTRO_ID_LIKE="$DISTRO_ID"
            DISTRO_VERSION=$(uname -r)
            ;;
    esac
}

detect_platform() {
    # PLATFORM is the basename used to look up lib/os/<platform>.sh.
    case "$OS" in
        Darwin)  PLATFORM="darwin" ;;
        FreeBSD) PLATFORM="freebsd" ;;
        OpenBSD) PLATFORM="openbsd" ;;
        SunOS)   PLATFORM="sunos" ;;
        Linux)
            case ":$DISTRO_ID:$DISTRO_ID_LIKE:" in
                *:debian:*|*:ubuntu:*)         PLATFORM="linux-debian" ;;
                *:fedora:*)                    PLATFORM="linux-fedora" ;;
                *:rhel:*|*:centos:*|*:rocky:*|*:almalinux:*) PLATFORM="linux-rhel" ;;
                *:arch:*)                      PLATFORM="linux-arch" ;;
                *:suse:*|*:opensuse*:*|*:sles:*) PLATFORM="linux-suse" ;;
                *)                             PLATFORM="linux-unknown" ;;
            esac ;;
        *) PLATFORM="unknown" ;;
    esac
}

detect_vm() {
    IS_VM="unknown"
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        if [ "$(systemd-detect-virt 2>/dev/null)" = "none" ]; then
            IS_VM="no"
        else
            IS_VM="yes"
        fi
    fi
}

detect_sudo() {
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        SUDO=""
    fi
}

detect_bash_version() {
    if [ -n "${BASH_VERSINFO+x}" ]; then
        BASH_MAJOR="${BASH_VERSINFO[0]}"
    else
        BASH_MAJOR=""
    fi
}

detect_all() {
    detect_os
    detect_distro
    detect_platform
    detect_vm
    detect_sudo
    detect_bash_version
}
