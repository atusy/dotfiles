function __zoxide_list_missing
  diff \
    ( zoxide query --list | sort | psub ) \
    (
      begin
        ghq list -p
        find "$HOME/.local/share/nvim/lazy" -maxdepth 1 -type d
      end  | sort | psub 
    ) \
    | string match --regex --entire '^> ' \
    | string replace -r '^> ' ''
end

function __zoxide_add_missing
  set -l missing ( __zoxide_list_missing )
  if test ( count $missing ) -gt 0
    zoxide add $missing
  end
end

function z --description 'zoxide wrapper'
  __zoxide_add_missing
  if test (count $argv) -eq 1
    __zoxide_z $argv || true
  else
    __zoxide_zi $argv || true
  end
end
