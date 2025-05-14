if ! status is-interactive
  if set -q DDCVIM
    # for Ex-command completions with ddc.vim
    alias Gin=git
    alias GinBuffer=git
    alias Make=make
    alias lmake=make
  end
  return
end

# for interactive shell
set -U fish_greeting

if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

source_hook mise activate fish
source_hook direnv hook fish
source_hook zoxide init fish --no-cmd

if type -q brew
  __setup-fish brew
else
  for brew in "$HOME/.linuxbrew/bin/brew" "/opt/homebrew/bin/brew"
    if test -x $brew
      __setup-fish $brew
    end
  end
end

abbr -a kunset 'kubectl config unset current-context'
abbr -a ping 'ping -c 5'
abbr -a top htop
abbr -a df duf
abbr -a ps procs
abbr -a du gdu
abbr -a vim nvim
abbr -a --set-cursor math 'math "%"'
abbr -a ll 'eza --long --group --time-style=long-iso'
abbr -a y --function __abbr-yank

bind \t complete-and-search-if-not-empty
bind \cr set_commandline_from_history
bind \cc cancel-commandline

if set -q "NVIM"
  function _nvim-preexec --on-event fish_preexec --wraps __nvim-preexec
    __nvim-preexec $argv
  end
  if type -q nvr
    set -gx EDITOR 'nvr -c "set bufhidden=delete" --remote-tab-wait'
  end
else
  set -gx EDITOR nvim
end

# NOTE: seems like completion works without them
# update_completion gh completion -s fish
# update_completion mise completion fish
# update_completion deno completions fish
# update_completion task --completion fish

set -l local_config (dirname (status -f))/local.fish
if test -f $local_config
  source $local_config
end
