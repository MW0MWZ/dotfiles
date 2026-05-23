# lib/os/linux-alpine.sh - Alpine Linux.

os_update() {
    ${SUDO} apk update
    ${SUDO} apk upgrade
}
