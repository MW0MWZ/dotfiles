# mosh quality-of-life. Skipped silently when mosh isn't installed.

command -v mosh >/dev/null 2>&1 || return 0

alias m='mosh'

# Hostname completion for `m` and `mosh`, when the bash-completion
# framework has loaded _known_hosts already (see 050_completion_framework).
if declare -f _known_hosts >/dev/null 2>&1; then
    complete -F _known_hosts m mosh
fi
