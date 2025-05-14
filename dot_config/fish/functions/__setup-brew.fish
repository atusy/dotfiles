function __setup-brew
  set -l brew $argv[1]
  set -l cache "$HOME/.cache/brew"
  if not test -r $cache/shellenv.fish; or test $cache/shellenv.fish -ot $brew
    mkdir -p $cache
    $brew shellenv > $cache/shellenv.fish
  end
  source $cache/shellenv.fish
  break
end
