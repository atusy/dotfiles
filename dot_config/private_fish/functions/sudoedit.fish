function sudoedit
  if set -qx EDITOR
    command sudoedit $argv
  else
    set -lx EDITOR ( type --force-path nvim )
    command sudoedit $argv
  end
end
