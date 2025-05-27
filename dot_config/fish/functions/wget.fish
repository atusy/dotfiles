function wget
  if type -q wget2
    command wget2 -c $argv
  else
    command wget -c $argv
  end
end
