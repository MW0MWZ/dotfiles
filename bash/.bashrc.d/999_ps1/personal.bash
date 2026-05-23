# PS1 — two-line prompt: user@host, cwd, then composable segments
# (git branch, direnv, ...) joined with " | " when present.
#
# Escapes use \001/\002 (Ctrl-A / Ctrl-B) so readline counts them as
# zero-width both when interpolated by PS1 and when emitted from
# command substitutions inside __ps1_segments.

_C_RESET=$'\001\e[0m\002'
_C_RED=$'\001\e[31m\002'
_C_GREEN=$'\001\e[32m\002'
_C_YELLOW=$'\001\e[33m\002'
_C_BLUE=$'\001\e[34m\002'

# ----- segment: git branch (with dirty marker) -----
__git_branch_ps1() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    local branch dirty colour
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || branch=$(git rev-parse --short HEAD 2>/dev/null) \
        || return 0
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        colour="$_C_YELLOW"; dirty='*'
    else
        colour="$_C_GREEN";  dirty=''
    fi
    printf '%sbranch%s: %s%s%s%s' "$_C_BLUE" "$_C_RESET" "$colour" "$branch" "$dirty" "$_C_RESET"
}

# ----- segment: direnv -----
__direnv_ps1() {
    [ -z "${DIRENV_DIR:-}" ] && return 0
    command -v direnv >/dev/null 2>&1 || return 0
    local dir colour
    # DIRENV_DIR is prefixed with "-" (a direnv quirk); strip it.
    dir=$(basename "${DIRENV_DIR#-}")
    if direnv status 2>/dev/null | grep -q "Found RC allowed true"; then
        colour="$_C_GREEN"
    else
        colour="$_C_YELLOW"
    fi
    printf '%sdirenv%s: %s%s%s' "$_C_BLUE" "$_C_RESET" "$colour" "$dir" "$_C_RESET"
}

# Compose segments: each function prints either nothing or a single
# segment. Non-empty segments get joined into " | seg1 | seg2 | ..."
# so the leading separator only appears when at least one segment is
# active.
__ps1_segments() {
    local out=""
    local fn seg
    for fn in __git_branch_ps1 __direnv_ps1; do
        seg=$($fn)
        [ -z "$seg" ] && continue
        out="${out} | ${seg}"
    done
    printf '%s' "$out"
}

PS1='┌['
PS1+="${_C_GREEN}"'\u'"${_C_BLUE}"'@'"${_C_GREEN}"'\h'"${_C_RESET}"
PS1+=' | '"${_C_BLUE}"'cwd: '"${_C_GREEN}"'\w'"${_C_RESET}"
PS1+='$(__ps1_segments)'
PS1+=']\n└$ '

# direnv ships its own prompt, suppress it (we render our own segment).
export DIRENV_LOG_FORMAT=""
