set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_BUNDLE_FILE $XDG_CONFIG_HOME/homebrew/brewfile
set -gx HOMEBREW_CASK_OPTS --no-quarantine
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
set -gx MISE_FISH_AUTO_ACTIVATE 0

for bindir in /usr/local/bin /opt/homebrew/bin
    test -d $bindir && fish_add_path --global --prepend $bindir
end

type -q brew && eval (brew shellenv)

fish_add_path --global --prepend /opt/homebrew/opt/curl/bin

if type -q gdu
    fish_add_path --global --prepend $HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin
end

if type -q gsed
    fish_add_path --global --prepend $HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin
end

if type -q gawk
    fish_add_path --global --prepend $HOMEBREW_PREFIX/opt/gawk/libexec/gnubin
end

if type -q gfind
    fish_add_path --global --prepend /opt/homebrew/opt/findutils/libexec/gnubin
end
