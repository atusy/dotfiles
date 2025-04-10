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
      cat "$HOME/.zsh_history" \
        | perl -ne 'chomp; if (s/\\\\$//) {print "$_\0"} else {print "$_\n"}' \
        | perl -e 'print reverse <>' \
        | perl -pe 's/\0/\\\\\n/g' \
        | perl -ne 'chomp; if (s/\\\\$//) {print "$_\n"} else {print "$_\0"}'
    end
  end | fzf --no-sort --exact --read0 $argv
end
