# direnv shell hook. Skipped silently when direnv isn't installed.
#
# Per-directory environment via `.envrc` files. Run `direnv allow` once
# in a directory to opt in. The PS1 segment in 999_ps1/ shows the
# active envrc with a colour reflecting allow/blocked state.

command -v direnv >/dev/null 2>&1 || return 0

eval "$(direnv hook bash)"
