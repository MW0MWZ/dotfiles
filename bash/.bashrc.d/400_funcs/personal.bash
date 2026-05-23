# Personal shell functions.

# Extract whatever archive you throw at it.
extract() {
    if [ ! -f "$1" ]; then
        printf '%s is not a file\n' "$1" >&2
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar)     tar xf  "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.zip)     unzip "$1" ;;
        *.rar)     unrar e "$1" ;;
        *.7z)      7z x "$1" ;;
        *.Z)       uncompress "$1" ;;
        *) printf "don't know how to extract %s\n" "$1" >&2; return 1 ;;
    esac
}

# Tarball a directory.
maketar() { tar cvzf "${1%%/}.tar.gz" "${1%%/}/"; }

# Zip a file or directory.
makezip() { zip -r "${1%%/}.zip" "$1"; }

# Run a command N times: `repeat 5 echo hi`.
repeat() {
    local i max
    max=$1; shift
    for ((i = 1; i <= max; i++)); do
        eval "$@"
    done
}

# Strip the prompt for clean copy/paste sessions.
blank_ps1() {
    export _PS1_BAK="$PS1"
    export PS1='$ '
}
unblank_ps1() {
    [ -z "${_PS1_BAK:-}" ] && return
    export PS1="$_PS1_BAK"
    unset _PS1_BAK
}

# Used by the PS1 builder. Joins args with the first arg as separator,
# skipping empty entries.
join_by() {
    local sep="$1"; shift
    local out=""
    local arg
    for arg in "$@"; do
        [ -z "$arg" ] && continue
        if [ -z "$out" ]; then
            out="$arg"
        else
            out="${out}${sep}${arg}"
        fi
    done
    printf '%s' "$out"
}
