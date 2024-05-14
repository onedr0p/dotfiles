if status is-interactive
  if type -q starship
    starship init fish | source
  end
end
