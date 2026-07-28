if type -q mise
    if test "$VSCODE_RESOLVING_ENVIRONMENT" = 1
        mise activate fish --shims | source
    else if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
