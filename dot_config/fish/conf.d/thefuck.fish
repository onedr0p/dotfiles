if status is-interactive
  if type -q direnv
    direnv hook fish | source
  end
end
