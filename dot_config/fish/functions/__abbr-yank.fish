function __abbr-yank
  echo 'base64 --wrap=0 | xargs -I{} echo -n -e "\e]52;;{}\e\\\\"'
end
