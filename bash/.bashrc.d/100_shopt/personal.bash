# Bash shell options. Names below are all safe on bash 3.2.

# Re-check LINES/COLUMNS after each command.
shopt -s checkwinsize

# Don't expand the entire PATH on a blank-line tab.
shopt -s no_empty_cmd_completion

# `cd foo` works even when you typed `Foo`.
shopt -s nocaseglob 2>/dev/null || true

# Trim long pathnames in PS1's \w to ~30 chars on bash 4+.
if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
    PROMPT_DIRTRIM=3
    # Recursive globbing with `**` for ad-hoc shell use.
    shopt -s globstar
fi
