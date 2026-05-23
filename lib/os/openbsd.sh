# lib/os/openbsd.sh - OpenBSD.

os_update() {
    case "$ARCH" in
        amd64|i386|arm64)
            ${SUDO} syspatch || true ;;
    esac
    ${SUDO} pkg_add -u -v
    ${SUDO} pkg_delete -a || true
}
