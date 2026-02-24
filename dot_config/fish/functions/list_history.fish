function list_history --description "List command history of Fish and Zsh at once"
  # Fish history
  history --null | string collect

  # Zsh history
  if test -f "$HOME/.zsh_history"
    # Convert Zsh history to be NULL separated
    # - Zsh history is separated by linebreaks
    # - Multilined item is represented by lines ending with backslashes
    # - Prepends NULL byte to connect with Fish history
    perl -e '
      my @entries;
      my $current = "";
      while (<STDIN>) {
        chomp;
        if (s/\\\\$//) {
          $current .= $_ . "\\\\\n";
        } else {
          $current .= $_;
          push @entries, $current;
          $current = "";
        }
      }
      push @entries, $current if $current ne "";
      print "\0" . join("\0", reverse @entries);
    ' < "$HOME/.zsh_history"
  end
end
