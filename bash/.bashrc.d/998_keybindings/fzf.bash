# fzf shell integration. Skipped silently when fzf isn't installed.
#
# Keybindings:
#   Ctrl-R   fuzzy history search
#   Ctrl-T   file picker into command line
#   Alt-C    cd into a fuzzy-selected directory
# Completion: triggered by typing **<TAB> on supported commands.

command -v fzf >/dev/null 2>&1 || return 0

# Pattern A: fzf's own user installer writes a single combined file
# at ~/.fzf.bash that sources keybindings + completion + path tweaks.
if [ -r "$HOME/.fzf.bash" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.fzf.bash"
    return 0
fi

# Pattern B: distro / Homebrew packages split keybindings.bash and
# completion.bash into a shared directory. Walk known locations and
# source the first pair we find.
for _fzf_dir in \
    /opt/homebrew/opt/fzf/shell \
    /usr/local/opt/fzf/shell \
    /usr/share/doc/fzf/examples \
    /usr/share/fzf \
    /usr/local/share/fzf/shell
do
    if [ -r "$_fzf_dir/key-bindings.bash" ]; then
        # shellcheck disable=SC1090
        . "$_fzf_dir/key-bindings.bash"
        # shellcheck disable=SC1090
        [ -r "$_fzf_dir/completion.bash" ] && . "$_fzf_dir/completion.bash"
        break
    fi
done
unset _fzf_dir
