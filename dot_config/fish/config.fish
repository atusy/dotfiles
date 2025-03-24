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
  # setup nix
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish

  # setup lazy completions
  if test -f /nix/var/nix/profiles/default/share/fish/vendor_completions.d/nix.fish
    if test ! -f $HOME/fish/completions/nix.fish
      mkdir -p $HOME/fish/completions
      ln -s /nix/var/nix/profiles/default/share/fish/vendor_completions.d/nix.fish $HOME/fish/completions/nix.fish
    end
  end
end

source_hook mise activate fish
source_hook direnv hook fish
source_hook zoxide init fish --no-cmd

for brew in brew /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew
  if set -l brewpath (type --path $brew)
    set -l cache "$HOME/.cache/brew"
    if not test -r $cache/shellenv.fish; or test $cache/shellenv.fish -ot $brew
      mkdir -p $cache
      $brew shellenv > $cache/shellenv.fish
    end
    source $cache/shellenv.fish
    break
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
abbr -a ll eza --long --group --time-style=long-iso
abbr -a y --function __abbr-yank
abbr -a Task "task -g"

alias cat='bat'
alias ls='eza'
alias ip='ip --color=auto'

bind \t complete-and-search-if-not-empty
bind \cr set_commandline_from_history
bind \cc cancel-commandline

if set -q "NVIM"
  function _nvim-preexec --on-event fish_preexec --wraps __nvim-preexec
    __nvim-preexec $argv
  end
end

update_completion gh completion -s fish
update_completion mise completion fish
update_completion deno completions fish
update_completion poetry completions fish
update_completion task --completion fish

set -l local_config (dirname (status -f))/local.fish
if test -f $local_config
  source $local_config
end
