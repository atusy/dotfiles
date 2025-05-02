function __zoxide_list_missing
  diff \
    ( zoxide query --list | sort | psub ) \
    ( ghq list -p | sort | psub ) \
    | grep '^> ' | string replace -r '^> ' ''
end

function __zoxide_add_missing
  set -l missing ( __zoxide_list_missing )
  if test ( count $missing ) -gt 0
    zoxide add $missing
  end
end

# function __z_record_history --on-variable PWD
#   mkdir -p $HOME/.cache/fish-zoxide
#   set -l prev = $dirprev[-1]
#   echo '["'$prev'","'$PWD'"]' >> $HOME/.cache/fish-zoxide/data.json
# end
#
# function __z_get_bonus_targets()
#   cat "$HOME/.cache/fish-zoxide/data.json" | jq -r '. | select(.[0] == "'$PWD'") | .[1]' 
# end
#
# function __z_bonus()
#   set -l scores "$argv[1]"
#   set -l n = (count $scores)
#   set -l median_idx = (math -s 0 "$n / 2 + 1")
#   echo "$scores" | head -n $median_idx | tail -n 1 | string match -r '[0-9]+([.][0-9]+)?'
# end
#
# function __z_zi()
#   set -l base_list ( zoxide query --list )
#   set -l bonus ( _z_bonus "$base_list" )
#   set -l list
#   for i in $base_list
#     set -l score ( string match  -r '[0-9]+([.][0-9]+)?' "$i"  )
#   end
# end

# sort -g -r

function z --description 'zoxide wrapper'
  __zoxide_add_missing
  if test (count $argv) -eq 1
    __zoxide_z $argv || true
  else
    __zoxide_zi $argv || true
  end
end
