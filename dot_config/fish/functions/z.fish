function __zi_query
    begin
        zoxide query --list
        ghq list -p
        find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -type d
    end \
        | perl -ne 'print unless $seen{$_}++' \
        | fzf --layout=reverse --no-sort --height=~15 $argv
end

function z --description 'zoxide wrapper'
    if test (count $argv) -eq 1
        if test -t 1
            __zoxide_z $argv || true
        else
            zoxide query $argv
        end
    else
        set -l selected (__zi_query --query="$argv")
        if test -t 1
            __zoxide_cd "$selected"
        else
            echo "$selected"
        end
    end
end
