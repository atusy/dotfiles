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

if not test -x ~/.local/bin/mise
  curl https://mise.run | sh
  ~/.local/bin/mise install
end
~/.local/bin/mise activate fish | source
direnv hook fish | source
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

# HACK: fish support for gh-fzf
function gh
  set -l ghf $HOME/ghq/github.com/atusy/gh-fzf/bin/ghf 

  # bootstrap
  if ! test -x $ghf
    ghq get atusy/gh-fzf
  end

  # hacks
  if ! test -t 0
    cat - | xargs gh $argv
  else if test -t 1 || set -q _GH_FZF_VIEWER
    $ghf $argv
  else
    _GH_FZF_VIEWER=id $ghf $argv
  end
end
