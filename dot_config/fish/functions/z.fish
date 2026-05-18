function __zi
  begin
    zoxide query --list
    ghq list -p
    find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -type d
  end \
    | perl -ne 'print unless $seen{$_}++' \
    | fzf --layout=reverse --no-sort --height=~15 $argv \
    | read -l result
  and __zoxide_cd $result
end

function z --description 'zoxide wrapper'
  if test (count $argv) -eq 1
    __zoxide_z $argv || true
  else
    __zi --query="$argv"
  end
end
