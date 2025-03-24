function source_hook
  set -l cmd ( type --force-path $argv[1] 2>/dev/null ); or return
  set -l outdir $HOME/.cache/fish/hooks
  set -l outfile $outdir/$argv[1].fish
  if not test $outfile -nt $cmd # is true when out is not found or older than cmd
    mkdir -p $outdir
    $cmd $argv[2..-1] > $outfile
  end
  source $outfile
end
