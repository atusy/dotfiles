function search_history
  begin
    history --null | string collect
    if test -f ~/.zsh_history
      echo -n -e '\0'
      cat ~/.zsh_history \
        | perl -ne 'chomp; if (s/\\\\$//) {print "$_\0"} else {print "$_\n"}' \
        | tac \
        | perl -pe 's/\0/\\\\\n/g' \
        | perl -ne 'chomp; if (s/\\\\$//) {print "$_\n"} else {print "$_\0"}'
    end
  end | fzf --no-sort --exact --read0 $argv
end
