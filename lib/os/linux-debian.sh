# lib/os/linux-debian.sh - Debian / Ubuntu / derivatives.

os_update() {
    ${SUDO} apt-get update
    ${SUDO} apt-get upgrade -y --fix-missing --fix-broken
    ${SUDO} apt-get dist-upgrade -y --fix-missing --fix-broken
    ${SUDO} apt-get autoremove -y
    ${SUDO} apt-get clean

    if [ "${IS_VM:-unknown}" = "no" ] && command -v fwupdmgr >/dev/null 2>&1; then
        ${SUDO} fwupdmgr refresh --force || true
        ${SUDO} fwupdmgr get-updates || true
        ${SUDO} fwupdmgr update -y || true
    fi
}
