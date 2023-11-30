function mkpass --description 'create a random password'
    if test (count $argv) -gt 0
        openssl rand -hex $argv
    else
        openssl rand -hex 12
    end
end
