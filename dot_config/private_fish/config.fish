# for neovim completions with ddc.vim
if ! status is-interactive
  if set -q DDCVIM
    alias Gin=git
    alias GinBuffer=git
    alias Make=make
    alias lmake=make
  end
  return
end

# for interactive shell
set -U fish_greeting

if not test -x ~/.local/bin/mise
  curl https://mise.run | sh
  ~/.local/bin/mise install
end
~/.local/bin/mise activate fish | source
direnv hook fish | source
zoxide init fish --no-cmd | source

abbr -a kunset 'kubectl config unset current-context'
abbr -a cpr 'gh pr | gh pr checkout'
abbr -a wpr 'gh pr view --web'
abbr -a wrepo 'gh repo view --web'
abbr -a wissue 'gh issue view --web'
abbr -a ping 'ping -c 5'
abbr -a top htop
abbr -a df duf
abbr -a ps procs
abbr -a du gdu
abbr -a vim nvim
abbr -a --set-cursor math 'math "%"'

alias cat='bat'
alias ll='eza --long --group --time-style=long-iso'
alias ls='eza'
alias ip='ip --color=auto'

bind \t complete-and-search
bind \cr set_commandline_from_history

function update_completion
  set -l cmd ( type --force-path $argv[1] ); or return
  set -l out $HOME/.config/fish/completions/$argv[1].fish
  if not test $out -nt $cmd
    $cmd $argv[2..-1] > $out
  end
end

mkdir -p $HOME/.config/fish/completions
update_completion gh completion -s fish
update_completion mise completion fish
update_completion deno completions fish
update_completion poetry completions fish
