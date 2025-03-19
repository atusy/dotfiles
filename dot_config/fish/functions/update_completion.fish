function update_completion
  set -l cmd ( type --force-path $argv[1] 2>/dev/null ); or return
  set -l out $HOME/.config/fish/completions/$argv[1].fish
  if not test $out -nt $cmd # is true when out is not found or older than cmd
    mkdir -p $HOME/.config/fish/completions
    $cmd $argv[2..-1] > $out
  end
end
