function set_commandline_from_history
  set -l cbuf ( commandline -b $buf )
  if set -l nbuf ( search_history --query=$cbuf ); and test -n $nubf
    commandline -r $nbuf
  end
end
