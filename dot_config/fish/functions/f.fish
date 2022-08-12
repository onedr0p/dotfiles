function f --wraps=fuck --description 'fuck shorthand'
    if count $argv > /dev/null
        fuck $argv
    else
        fuck
    end
end
