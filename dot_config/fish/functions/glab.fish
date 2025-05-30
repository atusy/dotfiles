# HACK: fish support for gh-fzf
function glab
  set -l glabf $HOME/ghq/github.com/atusy/gh-fzf/bin/glabf

  # bootstrap
  if ! test -x $glabf
    ghq get atusy/gh-fzf
  end

  # hacks
  if ! test -t 0
    cat - | xargs --no-run-if-empty gh $argv
  else if test -t 1 || set -q _GH_FZF_VIEWER
    $glabf $argv
  else
    _GH_FZF_VIEWER=id $glabf $argv
  end
end
