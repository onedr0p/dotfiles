if status is-interactive
  if type -q thefuck
    thefuck --alias | source
  end
end
