# lib/os/linux-rhel.sh - RHEL / CentOS / Rocky / Alma.

os_update() {
    if command -v dnf >/dev/null 2>&1; then
        ${SUDO} dnf upgrade --refresh -y
        ${SUDO} dnf autoremove -y
    else
        ${SUDO} yum upgrade -y
        ${SUDO} yum autoremove -y
    fi
}
