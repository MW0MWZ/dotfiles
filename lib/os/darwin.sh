# lib/os/darwin.sh - update routine for macOS.

os_update() {
    if [ ! -d "/Library/Developer/CommandLineTools/usr/bin" ]; then
        printf '[update] Xcode CLI tools missing -- requesting install.\n'
        ${SUDO} xcode-select --install || true
        printf '[update] Re-run update.sh once CLI tools finish installing.\n'
        return 1
    fi

    export HOMEBREW_NO_ENV_HINTS=1

    if ! command -v brew >/dev/null 2>&1; then
        printf '[update] Installing Homebrew...\n'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to current shell env so the rest of this run sees it.
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    brew update
    brew upgrade
    brew upgrade --cask --greedy || true   # casks aren't always upgradeable; don't fail the run
    brew autoremove
    brew cleanup -s

    # macOS / Apple updates
    softwareupdate -l || true
    local pending
    pending=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist LastRecommendedUpdatesAvailable 2>/dev/null || echo 0)
    if [ "${pending:-0}" -gt 0 ]; then
        ${SUDO} softwareupdate --install --recommended --agree-to-license
    fi
}
