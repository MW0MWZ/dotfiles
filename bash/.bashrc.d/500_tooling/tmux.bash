# tmux quality-of-life. Skipped if tmux isn't on PATH.

command -v tmux >/dev/null 2>&1 || return 0

alias tm='tmux'
alias tma='tmux attach -t'
alias tml='tmux list-sessions'
alias tmn='tmux new -s'
alias tmk='tmux kill-session -t'

# Attach to an existing session, or create one named after the cwd if
# none exist.
tmx() {
    if [ -n "$1" ]; then
        tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
        return
    fi
    if tmux list-sessions >/dev/null 2>&1; then
        tmux attach
    else
        tmux new -s "$(basename "$PWD")"
    fi
}
