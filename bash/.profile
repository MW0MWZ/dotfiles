# ~/.profile - sourced by login shells (any sh-like shell).
#
# Put PATH and environment-variable tweaks in ~/.profile.d/**/*.bash so
# they exist in non-interactive sessions too (cron, scp, etc).

if [ -d "$HOME/.profile.d" ]; then
    # The **/*.bash pattern works on bash 4 with globstar (recursive)
    # and on bash 3.2 without it (one level), since drop-ins live at
    # exactly one level deep.
    for f in "$HOME"/.profile.d/**/*.bash; do
        [ -r "$f" ] && . "$f"
    done
    unset f
fi

# Per-host overrides: not tracked by the dotfiles repo, edit freely.
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
