# My some-what useful commit function
# Typing `commit feat! terraform update lock file` will become
# `feat(terraform)!: update lock file`
function commit --description 'git conventional commits'
    set commit_message
    if count $argv > /dev/null
        set commit_type $argv[1]
        set breaking_change_char ""
        if string match '*!' $commit_type
            set breaking_change_char "!"
            set commit_type (string trim --chars="!" $commit_type)
        end
        set commit_scope $argv[2]
        set commit_description (string join " " $commit_description $argv[3..-1])
        set commit_message "$commit_type($commit_scope)$breaking_change_char: $commit_description"
        git commit -s -m "$commit_message"
    else
        set whatthecommit (curl -s http://whatthecommit.com/index.txt)
        set commit_message "chore: $whatthecommit"
        git commit -s -m "$commit_message" -m "Commit generated by whatthecommit.com"
    end
    if type -q lolcat
        printf "\nCommit message ~ "%s"\n" $commit_message | lolcat
    else
        printf "\nCommit message ~ "%s"\n" $commit_message
    end
end
