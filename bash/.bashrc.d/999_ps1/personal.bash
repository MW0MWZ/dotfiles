# PS1 — two-line prompt: user@host, cwd, git branch (when in a repo).
#
# Colour escapes use \001/\002 (Ctrl-A / Ctrl-B) so readline counts them
# as zero-width both when interpolated by PS1 and when emitted from
# command substitutions like __git_branch_ps1.

_C_RESET=$'\001\e[0m\002'
_C_RED=$'\001\e[31m\002'
_C_GREEN=$'\001\e[32m\002'
_C_YELLOW=$'\001\e[33m\002'
_C_BLUE=$'\001\e[34m\002'

# Emits "branch: <name>" with a colour that reflects clean/dirty.
# Empty output (and silent) when not in a git work tree.
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

PS1='┌['
PS1+="${_C_GREEN}"'\u'"${_C_BLUE}"'@'"${_C_GREEN}"'\h'"${_C_RESET}"
PS1+=' | '"${_C_BLUE}"'cwd: '"${_C_GREEN}"'\w'"${_C_RESET}"
PS1+='$(b=$(__git_branch_ps1); [ -n "$b" ] && printf " | %s" "$b")'
PS1+=']\n└$ '
