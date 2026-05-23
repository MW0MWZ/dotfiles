# lib/os/linux-fedora.sh - Fedora.

os_update() {
    ${SUDO} dnf upgrade --refresh -y
    ${SUDO} dnf autoremove -y

    if [ "${IS_VM:-unknown}" = "no" ] && command -v fwupdmgr >/dev/null 2>&1; then
        ${SUDO} fwupdmgr refresh --force || true
        ${SUDO} fwupdmgr get-updates || true
        ${SUDO} fwupdmgr update -y || true
    fi
}
