function _list_suggestions_to_set_commandline
  set -l cbuf ( commandline -b )
  list_history --query=$cbuf
  if string match --quiet --regex "^[^\s]*" "$cbuf"
    complete -C "$cbuf" | string match --regex '^[^\s]+' | while read -l cmd
      echo -n -e $cmd"\0"
    end
  end
end

function _select_suggestion_to_set_commandline
  _list_suggestions_to_set_commandline | fzf --no-sort --exact --read0 $argv
end

function set_commandline_from_suggestions
  set -l cbuf ( commandline -b )
  if set -l nbuf ( _select_suggestion_to_set_commandline --query=$cbuf ); and test -n $nubf
    commandline -r $nbuf
  end
end
