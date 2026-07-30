set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_BUNDLE_FILE $HOME/.config/homebrew/brewfile
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400

# HOMEBREW_PREFIX is exported, so nested shells inherit it and can skip shellenv
if not set -q HOMEBREW_PREFIX
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew $HOME/.linuxbrew/bin/brew
        if test -x $candidate
            eval ($candidate shellenv fish)
            break
        end
    end
end
