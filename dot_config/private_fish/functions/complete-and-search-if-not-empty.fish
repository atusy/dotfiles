function complete-and-search-if-not-empty
  set -l n (commandline -b $buf | string length)
  if test $n -gt 0
    commandline -f complete-and-search
  end
end

