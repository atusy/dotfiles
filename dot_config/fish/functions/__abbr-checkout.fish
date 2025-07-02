function __abbr-checkout
  set -l buf (commandline --current-process | string trim)
  if test "$buf" = "gh pr checkout"
    echo "checkout --detach"
    return 0
  end
  return 1
end
