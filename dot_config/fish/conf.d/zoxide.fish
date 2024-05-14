if status is-interactive
  if type -q zoxide
    zoxide init fish | source
  end
end
