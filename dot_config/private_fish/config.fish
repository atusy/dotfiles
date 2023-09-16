if status is-interactive
    # Commands to run in interactive sessions can go here
end

# for neovim completions with ddc.vim
if set -q DDCVIM
  alias Gin=git
  alias GinBuffer=git
end
