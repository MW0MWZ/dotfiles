# Login-shell environment.

# Prepend ~/.local/bin and ~/bin to PATH if present and not already there.
case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) [ -d "${HOME}/.local/bin" ] && export PATH="${HOME}/.local/bin:${PATH}" ;;
esac
case ":${PATH}:" in
    *":${HOME}/bin:"*) ;;
    *) [ -d "${HOME}/bin" ] && export PATH="${HOME}/bin:${PATH}" ;;
esac

# Pick the best available editor.
if command -v vim >/dev/null 2>&1; then
    export EDITOR="$(command -v vim)"
elif command -v vi >/dev/null 2>&1; then
    export EDITOR="$(command -v vi)"
elif command -v nano >/dev/null 2>&1; then
    export EDITOR="$(command -v nano)"
fi
export VISUAL="$EDITOR"
