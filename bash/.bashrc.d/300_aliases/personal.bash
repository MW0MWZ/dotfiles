# Aliases.

# Per-OS ls colour flag.
case "${OSTYPE:-$(uname -s)}" in
    linux-gnu*|Linux*|cygwin*|msys*) LS_COLOR=" --color=auto" ;;
    darwin*|Darwin*|freebsd*|FreeBSD*|openbsd*|OpenBSD*) LS_COLOR=" -G" ;;
    *) LS_COLOR="" ;;
esac

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# GNU ls supports --group-directories-first; BSD ls doesn't.
case "${OSTYPE:-$(uname -s)}" in
    linux-gnu*|Linux*|cygwin*|msys*)
        alias ls="ls -lhF --group-directories-first${LS_COLOR}" ;;
    *)
        alias ls="ls -lhF${LS_COLOR}" ;;
esac
alias ll='ls -a'
alias la='ls -A'

# Use bat in place of cat / less when present.
if command -v batcat >/dev/null 2>&1; then alias bat='batcat'; fi
if command -v bat   >/dev/null 2>&1; then
    alias cat='bat -p'
    alias less='bat -p --paging=always'
fi

# eza/exa supersede ls when present.
if command -v eza >/dev/null 2>&1; then
    alias ls="eza -lhF --group-directories-first"
elif command -v exa >/dev/null 2>&1; then
    alias ls="exa -lhF --group-directories-first"
fi

# Quality-of-life.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# Funsies (preserved from the old dotfiles).
alias coffeebreak='while [ true ]; do head -n 100 /dev/urandom; sleep 1; done | hexdump | grep "ca fe"'
