function __z_query
  zoxide query --list
  ghq list -p
  find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -type d
end

function __zi
  set -l result (
    __z_query | fzf --layout=reverse --no-sort --height=~15 $argv
  )
  and __zoxide_cd $result
end

function z --description 'zoxide wrapper'
  if test (count $argv) -eq 1
    __zoxide_z $argv || true
  else
    __zi --query="$argv"
  end
end
