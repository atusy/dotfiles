function search_history --description "Search command history of Fish and Zsh at once"
  begin
    # Fish history
    history --null | string collect

    # Zsh history
    if test -f "$HOME/.zsh_history"
      # Connection to Fish history
      echo -n -e '\0'

      # Convert Zsh history to be NULL separated
      # - Zsh history is separated by linebreaks
      # - Multilined item is represented by lines ending with backslashes
      perl -e '
        # Read all lines and join backslash-continued lines
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
        # Output in reverse order, NULL-separated
        print join("\0", reverse @entries);
      ' < "$HOME/.zsh_history"
    end
  end | fzf --no-sort --exact --read0 $argv
end
