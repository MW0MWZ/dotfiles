# lib/os/sunos.sh - Solaris 10 and 11.
#
# Solaris 10 has an aged CA bundle so curl/wget calls into the wider
# internet need certificate checking disabled. We don't repeat that here
# because update.sh itself only talks to local package mirrors via the
# system package tools.

os_update() {
    case "$DISTRO_VERSION" in
        5.10)
            if ! command -v pkgutil >/dev/null 2>&1; then
                printf '[update] OpenCSW pkgutil missing; bootstrap should have installed it.\n' >&2
                printf '[update] Falling back: yes | pkgadd -d http://get.opencsw.org/now all\n'
                yes | ${SUDO} pkgadd -d http://get.opencsw.org/now all || return 1
            fi
            /opt/csw/bin/pkgutil -U -u -y ;;
        5.11)
            ${SUDO} pkg update --accept || true
            if command -v pkgutil >/dev/null 2>&1; then
                /opt/csw/bin/pkgutil -U -u -y || true
            fi ;;
        *)
            printf '[update] Unsupported Solaris version: %s\n' "$DISTRO_VERSION" >&2
            return 1 ;;
    esac
}
