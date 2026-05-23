# lib/os/linux-arch.sh - Arch Linux.

os_update() {
    ${SUDO} pacman -Sy --noconfirm --needed archlinux-keyring
    ${SUDO} pacman -Syu --noconfirm
}
