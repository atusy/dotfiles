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
set -g __fish_git_prompt_showcolorhints 1
set -g fish_color_cwd yellow

~/.local/bin/mise activate fish | source
zoxide init fish --no-cmd | source

abbr -a kunset 'kubectl config unset current-context'
abbr -a cpr 'gh pr checkout'
abbr -a vrepo 'gh repo view --web'
abbr -a vissue 'gh issue view --web'
abbr -a vpr 'gh pr view --web'
alias cat='bat'
alias ll='eza -l --time-style=iso'
alias ls='eza'
alias sudo='sudo '
alias vim='nvim'
alias wget='wget -c'
