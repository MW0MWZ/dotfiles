# lib/stow.sh - run stow against each package, after backing up any
# pre-existing real files in $HOME that would conflict.
#
# The backup walker is tree-aware: when it finds a directory under the
# target that's already a symlink pointing into the repo (i.e. stow has
# previously folded that subtree), it does not descend into it. This
# makes re-stow idempotent and avoids the corruption that file-by-file
# walking would cause -- moving a file inside the folded directory
# would resolve through the symlink and rename a file in the repo.

backup_conflicts() {
    local pkg_dir="$1"
    local target_dir="$2"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    _bc_walk "$pkg_dir" "$target_dir" "$pkg_dir" "$ts"
}

# Resolve a symlink to an absolute path. Returns empty if not a link.
_bc_abs_link() {
    local lnk="$1" tgt
    tgt=$(readlink "$lnk" 2>/dev/null) || return 0
    case "$tgt" in
        /*) printf '%s' "$tgt" ;;
        *)  printf '%s/%s' "$(dirname "$lnk")" "$tgt" ;;
    esac
}

_bc_back_up() {
    local d="$1" ts="$2"
    printf '  backing up %s -> %s.bak.%s\n' "$d" "$d" "$ts"
    mv "$d" "$d.bak.$ts"
}

# Backup-or-skip a single file at the target. Skips if it's already
# the right symlink into the repo; otherwise moves out of the way.
_bc_handle_file() {
    local d="$1" src="$2" pkg_root="$3" ts="$4"
    if [ -L "$d" ]; then
        local link_target
        link_target=$(_bc_abs_link "$d")
        case "$link_target" in
            "$src"|"$pkg_root"/*) return 0 ;;
        esac
        _bc_back_up "$d" "$ts"
    elif [ -e "$d" ]; then
        _bc_back_up "$d" "$ts"
    fi
}

# Walk one level of the source tree, mirroring decisions on the target.
_bc_walk() {
    local src_dir="$1" dst_dir="$2" pkg_root="$3" ts="$4"
    local entry name d link_target

    while IFS= read -r entry; do
        name="${entry##*/}"
        d="$dst_dir/$name"

        if [ -d "$entry" ] && [ ! -L "$entry" ]; then
            # Source side is a real directory. Decide based on the target.
            if [ -L "$d" ]; then
                link_target=$(_bc_abs_link "$d")
                case "$link_target" in
                    "$entry"|"$pkg_root"/*)
                        # Already folded into our repo -- skip subtree.
                        continue ;;
                esac
                # Symlink to somewhere else -- back it up so stow can replace.
                _bc_back_up "$d" "$ts"
            elif [ -d "$d" ]; then
                # Real directory: recurse to inspect children.
                _bc_walk "$entry" "$d" "$pkg_root" "$ts"
            elif [ -e "$d" ]; then
                # Non-directory blocking the directory -- back it up.
                _bc_back_up "$d" "$ts"
            fi
        else
            _bc_handle_file "$d" "$entry" "$pkg_root" "$ts"
        fi
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1)
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
