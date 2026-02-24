function y
  base64 --wrap=0 | while read -l line; printf "\e]52;;%s\e\\" $line; end
end

