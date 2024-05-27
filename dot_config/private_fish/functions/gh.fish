# HACK: fish support for gh-fzf
function gh
  set -l ghf $HOME/ghq/github.com/atusy/gh-fzf/bin/ghf 

  # bootstrap
  if ! test -x $ghf
    ghq get atusy/gh-fzf
  end

  # hacks
  if ! test -t 0
    cat - | xargs gh $argv
  else if test -t 1 || set -q _GH_FZF_VIEWER
    $ghf $argv
  else
    _GH_FZF_VIEWER=id $ghf $argv
  end
end
