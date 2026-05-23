# lib/os/linux-suse.sh - openSUSE / SLES.

os_update() {
    ${SUDO} zypper refresh
    ${SUDO} zypper update -y
}
