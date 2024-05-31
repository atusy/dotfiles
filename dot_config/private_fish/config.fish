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
set -g fish_color_cwd yellow
set -g __fish_git_prompt_showcolorhints 1
set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_showupstream 1

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
abbr -a vim 'nvim'
abbr -a --set-cursor math 'math "%"'

alias cat='bat'
alias ll='eza --long --group --time-style=long-iso'
alias ls='eza'

bind \t complete-and-search
bind \cr set_commandline_from_history
