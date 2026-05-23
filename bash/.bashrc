#
# ~/.bashrc - sourced for interactive bash shells.
#
# .bash_profile sources this too, so the early portion (before the
# interactive-shell guard) is fine to run in login shells.
#

# Stop here for non-interactive shells.
case $- in
    *i*) ;;
    *) return ;;
esac

if [ -d "$HOME/.bashrc.d" ]; then
    for f in "$HOME"/.bashrc.d/**/*.bash; do
        [ -r "$f" ] && . "$f"
    done
    unset f
fi

# Per-host overrides: not tracked by the dotfiles repo, edit freely.
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
