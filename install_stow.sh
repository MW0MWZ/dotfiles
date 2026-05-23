#!/bin/sh
# install_stow.sh - userspace stow builder.
#
# Use this only when the system package manager can't install stow
# (e.g. Solaris 10 without OpenCSW's stow available, stripped-down
# BSDs, hosts where you don't have root). Installs into ~/.local by
# default; override with STOW_PREFIX.
#
# Requires: perl, make, curl|wget, tar, gzip.

set -eu

STOW_PREFIX="${STOW_PREFIX:-$HOME/.local}"

msg() { printf '[install_stow] %s\n' "$*"; }
err() { printf '[install_stow] error: %s\n' "$*" >&2; }

# Confirm prerequisites.
for tool in perl make tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        err "$tool is required but not installed."
        exit 1
    fi
done

if command -v curl >/dev/null 2>&1; then
    FETCH="curl -fsSL -o"
elif command -v wget >/dev/null 2>&1; then
    FETCH="wget -q -O"
else
    err "Need curl or wget to download stow source."
    exit 1
fi

TMPDIR_BUILD=$(mktemp -d 2>/dev/null || mktemp -d -t install_stow)
trap 'rm -rf "$TMPDIR_BUILD"' EXIT INT TERM

msg "Downloading GNU stow source..."
$FETCH "$TMPDIR_BUILD/stow.tar.gz" "https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

msg "Extracting..."
( cd "$TMPDIR_BUILD" && tar xzf stow.tar.gz )

src_dir=$(find "$TMPDIR_BUILD" -mindepth 1 -maxdepth 1 -type d -name 'stow-*' | head -n1)
if [ -z "$src_dir" ]; then
    err "Could not locate extracted source directory."
    exit 1
fi

msg "Building into $STOW_PREFIX"
mkdir -p "$STOW_PREFIX"
( cd "$src_dir" && ./configure --prefix="$STOW_PREFIX" && make install )

msg "stow installed at $STOW_PREFIX/bin/stow"
msg "Add to your PATH if it isn't already:"
msg "  export PATH=\"$STOW_PREFIX/bin:\$PATH\""
