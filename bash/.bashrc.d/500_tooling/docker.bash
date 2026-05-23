# Docker quality-of-life. Skipped if docker isn't on PATH.

command -v docker >/dev/null 2>&1 || return 0

alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dprune='docker system prune -af'

# `docker compose` (v2 subcommand) vs `docker-compose` (v1 binary).
if docker compose version >/dev/null 2>&1; then
    alias dc='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
    alias dc='docker-compose'
fi

# Stop every running container — handy when iterating locally.
dstop_all() {
    local ids
    ids=$(docker ps -q)
    [ -n "$ids" ] && docker stop $ids
}

# Drop into a shell inside a running container by name fragment.
dsh() {
    if [ -z "$1" ]; then
        printf 'usage: dsh <name-fragment> [shell]\n' >&2
        return 2
    fi
    local container shell
    container=$(docker ps --format '{{.Names}}' | grep -m1 "$1") || {
        printf 'no running container matching %s\n' "$1" >&2
        return 1
    }
    shell="${2:-bash}"
    docker exec -it "$container" "$shell"
}

# Source completion if bash-completion's framework is loaded and docker
# ships one. Homebrew installs it at $(brew --prefix)/etc/bash_completion.d.
if [ -n "${BASH_COMPLETION_VERSINFO:-}" ]; then
    for f in \
        /usr/share/bash-completion/completions/docker \
        /etc/bash_completion.d/docker \
        /opt/homebrew/etc/bash_completion.d/docker \
        /usr/local/etc/bash_completion.d/docker
    do
        [ -r "$f" ] && { . "$f"; break; }
    done
    unset f
fi
