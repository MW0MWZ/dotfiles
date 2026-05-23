# lib/os/linux-unknown.sh - fallback for unrecognised Linux distributions.

os_update() {
    printf '[update] Unrecognised Linux distribution (%s / %s).\n' "$DISTRO_ID" "$DISTRO_ID_LIKE" >&2
    printf '[update] Run your package manager manually.\n' >&2
    return 1
}
