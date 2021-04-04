function mkpass --description 'create a random 20 character string'
    openssl rand -base64 20 | fold -w1 | shuf | tr -d '\n' | clipy; pastey;
end
