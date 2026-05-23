# lib/os/freebsd.sh - FreeBSD.

os_update() {
    # Base system updates only apply on amd64 / i386 / arm64. Try and
    # ignore non-fatal failures on other archs.
    case "$ARCH" in
        amd64|i386|arm64)
            ${SUDO} freebsd-update fetch || true
            ${SUDO} freebsd-update install || true ;;
    esac
    ${SUDO} pkg update
    ${SUDO} pkg upgrade -y
}
