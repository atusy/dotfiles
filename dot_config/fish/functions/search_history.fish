function search_history --description "Search command history of Fish and Zsh at once"
  list_history | fzf --no-sort --exact --read0 $argv
end
