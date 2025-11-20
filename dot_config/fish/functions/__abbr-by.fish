function __bootstrap_by
  if functions -q by
    return 0
  end

  set -l root (ghq root)
  set -l repo "github.com/atusy/by-binds-yourself"
  set -l dir "$root/$repo"

  if not test -d "$dir"
    ghq get https://$repo
  end

  source "$dir/by.fish"
end

function __abbr-by
  __bootstrap_by
  echo "by"
end
