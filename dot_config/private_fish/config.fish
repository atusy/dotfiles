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
if test -f /nix/var/nix/profiles/default/share/fish/vendor_completions.d/nix.fish
  source /nix/var/nix/profiles/default/share/fish/vendor_completions.d/nix.fish
end

if not test -x ~/.local/bin/mise
  curl https://mise.run | sh
  ~/.local/bin/mise install
end
~/.local/bin/mise activate fish | source
direnv hook fish | source
zoxide init fish --no-cmd | source

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

alias cat='bat'
alias ls='eza'
alias ip='ip --color=auto'

bind \t complete-and-search-if-not-empty
bind \cr set_commandline_from_history

if set -q "NVIM"
  function _nvim-preexec --on-event fish_preexec --wraps __nvim-preexec
    __nvim-preexec $argv
  end
end

function update_completion
  set -l cmd ( type --force-path $argv[1] 2>/dev/null ); or return
  set -l out $HOME/.config/fish/completions/$argv[1].fish
  if not test $out -nt $cmd # is true when out is not found or older than cmd
    mkdir -p $HOME/.config/fish/completions
    $cmd $argv[2..-1] > $out
  end
end

update_completion gh completion -s fish
update_completion mise completion fish
update_completion deno completions fish
update_completion poetry completions fish

set -l local_config (dirname (status -f))/local.fish
if test -f $local_config
  source $local_config
end
