function set_commandline_from_history --description "A replacement of history-pager"
  set -l cbuf ( commandline -b )
  if set -l nbuf ( search_history --query=$cbuf ); and test -n $nubf
    commandline -r $nbuf
  end
end
