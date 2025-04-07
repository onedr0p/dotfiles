if type -q bat
    abbr cat bat
end

if type -q chezmoi
    abbr cm chezmoi
end

if type -q doggo
    abbr dig doggo
end

if type -q git
    abbr --command git co checkout
    abbr --command git pl pull --rebase --autostash
    abbr --command git pf push --force
end

if type -q kubectl
    abbr k kubectl
end

if type -q lsd
    abbr ls lsd
end
