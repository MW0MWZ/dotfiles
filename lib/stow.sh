# lib/stow.sh - run stow against each package directory, backing up any
# pre-existing real files at the target so stow doesn't refuse.
#
# Usage:
#   stow_packages <repo_dir> <target_dir> <pkg1> [<pkg2> ...]
#
# For each package, walks the package tree and for every file we'd
# symlink, if the corresponding target is a real file (not a symlink and
# not absent), move it to <path>.bak.<timestamp>.

backup_conflicts() {
    local pkg_dir="$1"
    local target_dir="$2"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)

    # Walk the package tree. Use find so we don't choke on dotfiles.
    local rel src dst
    while IFS= read -r src; do
        rel="${src#$pkg_dir/}"
        dst="$target_dir/$rel"
        # Skip if target doesn't exist, OR if it's already the symlink we want.
        if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
            continue
        fi
        if [ -L "$dst" ]; then
            # Existing symlink — if it points into the repo, leave it (idempotent re-stow).
            local link_target
            link_target=$(readlink "$dst" 2>/dev/null || true)
            case "$link_target" in
                "$src"|"$pkg_dir"/*) continue ;;
            esac
        fi
        # Real file or wrong-symlink — back it up.
        printf '  backing up %s -> %s.bak.%s\n' "$dst" "$dst" "$ts"
        mv "$dst" "$dst.bak.$ts"
    done < <(find "$pkg_dir" -type f)
}

stow_packages() {
    local repo="$1"; shift
    local target="$1"; shift

    if ! command -v stow >/dev/null 2>&1; then
        printf 'stow_packages: stow not on PATH\n' >&2
        return 1
    fi

    local pkg
    for pkg in "$@"; do
        local pkg_dir="$repo/$pkg"
        if [ ! -d "$pkg_dir" ]; then
            printf 'stow_packages: package %s missing at %s, skipping\n' "$pkg" "$pkg_dir" >&2
            continue
        fi
        printf '[stow] %s\n' "$pkg"
        backup_conflicts "$pkg_dir" "$target"
        stow --dir="$repo" --target="$target" --restow "$pkg"
    done
}
