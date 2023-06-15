function mkpass --description 'create a random password'
    if count $argv > /dev/null
        openssl rand -hex $argv
    else
        openssl rand -hex 12
    end
end
