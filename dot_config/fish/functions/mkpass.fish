function mkpass --description 'create a random password'
    set word_1 (shuf -n 1 /usr/share/dict/words)
    set word_2 (shuf -n 1 /usr/share/dict/words)
    set word_3 (shuf -n 1 /usr/share/dict/words)
    set password (string join '-' $word_1 $word_2 $word_3)
    string lower $password
end
