function complete-path-with-fzf --description 'Complete a file or directory with fd and fzf'
    set -l query (commandline --current-token --cut-at-cursor | string unescape)
    set -l selected (
        fd --type f --type d --print0 |
            fzf +m --read0 --print0 --height=~15 --layout=reverse --prompt='Path> ' --query="$query" |
            string split0
    )
    if set -q selected[1]
        commandline --current-token --replace -- (string escape -- "$selected[1]")
    end
end
