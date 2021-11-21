function f --wraps=fuck --description 'fuck shorthand'
    if test -n $argv
        fuck $argv
    else
        fuck
    end
end
