set -l root (ghq root)
set -l repo "github.com/atusy/by-binds-yourself"
set -l dir "$root/$repo"

if not test -d "$dir"
  ghq get https://$repo
end

source "$dir/functions/by.fish"
