# bash-completion framework.
#
# Sourcing the master initializer registers a dynamic completion loader,
# so any installed tool with a completion file under
# /usr/share/bash-completion/completions/ (or equivalent) gets tab-completion
# the first time you press <Tab> after it.
#
# Loaded early (050_) so subsequent drop-ins can rely on _known_hosts,
# _completion_loader, etc.

# Already loaded? bash-completion sets BASH_COMPLETION_VERSINFO once active.
[ -n "${BASH_COMPLETION_VERSINFO:-}" ] && return 0

for _bc_init in \
    /opt/homebrew/etc/profile.d/bash_completion.sh \
    /usr/local/etc/profile.d/bash_completion.sh \
    /usr/share/bash-completion/bash_completion \
    /usr/local/share/bash-completion/bash_completion \
    /etc/bash_completion \
    /opt/csw/etc/bash_completion
do
    if [ -r "$_bc_init" ]; then
        # shellcheck disable=SC1090
        . "$_bc_init"
        break
    fi
done
unset _bc_init
