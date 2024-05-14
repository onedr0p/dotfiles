if status is-interactive
  if type -q atuin
    atuin init fish --disable-up-arrow | source
  end
end
