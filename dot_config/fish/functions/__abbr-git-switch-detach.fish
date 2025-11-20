function __abbr-git-switch-detach
  set -l buf (commandline --current-process | string trim)
  set -l branch (string match --regex '^git (\S+)\s*$' "$buf")[2]
  if test "$branch" = 'dev' -o "$branch" = 'main' -o "$branch" = 'master'
    echo "fetch origin $branch && git switch origin/$branch --detach"
    return 0
  end
  return 1
end
