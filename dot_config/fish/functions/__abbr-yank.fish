function __abbr-yank
  for cmd in pbcopy wl-copy
    if type -q $cmd
      echo -n $cmd
      return
    end
  end
  echo 'base64 | xargs -I{} echo -n -e "\e]52;;{}\e\\\\"'
end
