function z --description 'zoxide wrapper'
  if test (count $argv) -eq 1
    __zoxide_z $argv || true
  else
    __zoxide_zi $argv || true
  end
end
