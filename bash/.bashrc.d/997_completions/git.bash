# Source git's bash completion if available.

command -v git >/dev/null 2>&1 || return 0

for f in \
    /usr/share/bash-completion/completions/git \
    /etc/bash_completion.d/git \
    /opt/homebrew/etc/bash_completion.d/git-completion.bash \
    /usr/local/etc/bash_completion.d/git-completion.bash
do
    [ -r "$f" ] && { . "$f"; break; }
done
unset f
