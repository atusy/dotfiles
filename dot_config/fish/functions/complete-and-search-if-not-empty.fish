function complete-and-search-if-not-empty
  set -l n (commandline -b | string length)
  if test (count $n -eq 1) -a $n -eq 0
    return
  end
  commandline -f complete-and-search
end

