function f --wraps=fuck --description 'fuck shorthand'
    if test (count $argv) -gt 0
        fuck $argv
    else
        fuck
    end
end
