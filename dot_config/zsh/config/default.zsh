function zsh-defer { # workaround for unexpected failure on loading zsh-defer
  "$@"
}

if [[ -n "${NVIM:-$NVIM_LISTEN_ADDRESS}" ]] && command -v nvr > /dev/null
then
  export NVIM_LISTEN_ADDRESS="${NVIM_LISTEN_ADDRESS:-$NVIM}"
  export EDITOR='nvr -cc "below split" --remote-wait-silent'
elif command -v nvim > /dev/null
then
  export EDITOR='nvim'
elif command -v vim > /dev/null
then
  export EDITOR='vim'
fi

if ! command -v sheldon >/dev/null; then
  if [[ ! -x "${HOME}/.local/bin/sheldon" ]]; then
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
      | bash -s -- --repo rossmacarthur/sheldon --to "${HOME}/.local/bin"
  fi
  sheldon() {
    "${HOME}/.local/bin/sheldon" "$@"
  }
fi

SHELDON_SOURCE="${HOME}/.cache/sheldon/plugins.zsh"
if [[ ! -r "$SHELDON_SOURCE.zwc" || "${HOME}/.config/sheldon/plugins.toml" -nt "$SHELDON_SOURCE"  ]]; then
  mkdir -p "$( dirname "$SHELDON_SOURCE" )"
  sheldon source > "$SHELDON_SOURCE"
  zcompile "$SHELDON_SOURCE"
fi
builtin source "$SHELDON_SOURCE"

# PROMPT
PROMPT_ACCENT_COLOR="$( test -n "$SSH_CLIENT" && echo cyan || echo 112 )"
PROMPT='%F{${PROMPT_ACCENT_COLOR}}[ %3~ ]%F{white}$( gitprompt 2>/dev/null ) $( [[ ! "${KUBE_PS1_CONTEXT}" =~ "^(BINARY-)?N/A$"  ]] && kube_ps1 2>/dev/null )
%F{${PROMPT_ACCENT_COLOR}}» '

bindkey -e
bindkey "^[[3~" delete-char # Del is delete-char, not tilde

# History
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt \
  hist_ignore_all_dups \
  hist_ignore_space \
  hist_no_store \
  hist_reduce_blanks \
  hist_save_no_dups \
  hist_verify \
  share_history \
  inc_append_history

# cd
setopt autocd auto_pushd pushd_ignore_dups

# else
setopt \
  extended_glob \
  mark_dirs \
  interactive_comments \
  noautoremoveslash \
  nomatch \
  notify \
  no_beep \
  no_flow_control \
  no_list_beep \
  numeric_glob_sort \
  print_eight_bit \
  prompt_subst

# completion
LISTMAX=1000
setopt \
  always_last_prompt \
  auto_list \
  auto_menu \
  auto_param_keys \
  auto_param_slash \
  complete_aliases \
  complete_in_word \
  list_types \
  magic_equal_subst \
  menu_complete

## zstyle
### Basic Configuration
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select interactive
zstyle ':completion:*' group-name ''
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list
zstyle ':completion:*' matcher-list  'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' auto-description 'Specify: %d'
zstyle ':completion:*' select-prompt %SScrolling Active: Current selection at %p%s
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*:options'         description 'yes'
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

### Highlight
# zstyle ':completion:*'              list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*'              list-colors "di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30"
zstyle ':completion:*:messages'     format "$YELLOW" '%d' "$DEFAULT"
zstyle ':completion:*:warnings'     format "$RED" 'No matches for:' "$YELLOW" '%d' "$DEFAULT"
zstyle ':completion:*:descriptions' format "$YELLOW" 'Completing %B%d%b' "$DEFAULT"
zstyle ':completion:*:corrections'  format "$YELLOW" '%B%d% ' "$RED" '(Errors: %e)%b' "$DEFAULT"

### Separator
zstyle ':completion:*'         list-separator ' ==> '
zstyle ':completion:*:manuals' separate-sections true

### Cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

### Others
zstyle ':completion:*' remote-access false
zstyle ':completion:*:sudo:*' command-path $path
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion::complete:*' use-cache true

# Edit command line with favorite editor
autoload -Uz edit-command-line
function edit-command-line2() {
  EDITOR="${EDITOR_ZSH:-$EDITOR}" edit-command-line
}
zle -N edit-command-line2
bindkey "^x^e" edit-command-line2

# Set title of the session according to the working directory
function update_session_title() {
  # .../github.com/atusy/dotfiles -> dotfiles
  # .../github.com/atusy/dotfiles/dot_config/nvim -> dotfiles/.../nvim
  # .../dotfiles/.worktree/branch -> dotfiles@branch
  # .../dotfiles/.worktree/branch/dot_config/nvim -> dotfiles@branch/.../nvim
  export SESSION_TITLE="${1:-${SESSION_TITLE:-}}"
  echo -en "\e]2;${SESSION_TITLE:-$( pwd | sed -E -e 's#.*/\.github\.com/##' -e "s#.*/([^/]+)/\.worktree/#\1@#" -e "s#/.*/#/.../#" -e "s#^/\.\.\./##" )}\a"
}
function init_update_session_title() {
  typeset -ag chpwd_functions;
  if [[ -z "${chpwd_functions[(r)update_session_title]+1}" ]]; then
    chpwd_functions=( update_session_title ${chpwd_functions[@]} )
  fi
  update_session_title
}
zsh-defer init_update_session_title

# Aliases and some useful functions
alias sudo='sudo '
alias ip='ip --color=auto'
alias ls='ls --color=auto'
alias ll='eza -l --time-style=iso'
alias top='htop'
alias df='duf'
alias ps='procs'
alias du='gdu'
alias cat='bat'
alias jq='gojq'
alias yq='gojq --yaml-input'
alias vim='nvim'
function my-zoxide-init() {
  if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh --no-cmd)"
    function z() {
      if [[ "$#" -eq 1 ]]
      then
        __zoxide_z "$@"
      else
        __zoxide_zi "$@"
      fi
    }
  fi
}
zsh-defer my-zoxide-init
if command -v wget2 > /dev/null
then
  alias wget='wget2 -c' # resumable
else
  alias wget='wget -c' # resumable
fi

if [[ -n $NVIM_LISTEN_ADDRESS ]] && command -v nvr > /dev/null; then
  function man() {
    if [[ $# -eq 1 ]]; then
      nvr -cc "Man $1" 2>/dev/null || command man "$1"
    else
      command man "$@"
    fi
  }
fi

if command -v xdg-open > /dev/null; then
  function open() {
    xdg-open "$@" 2>/dev/null
  }
fi

function kubeconfig() {
  local RES
  RES="$( find "${1:-${HOME}/.kube}" -mindepth 1 -maxdepth 1 -type f | grep -v '/kubectx$' | fzf --preview 'cat {}' )"
  [[ -f $RES ]] && export KUBECONFIG="$RES"
}
alias kunset='command kubectl config unset current-context'

# local configurations
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"

# .zshrc
if [[ ! -r "${HOME}/.zshrc.zwc" || "${HOME}/.zshrc" -nt "${HOME}/.zshrc.zwc" ]]; then
  zcompile "${HOME}/.zshrc"
fi

# compinit as lazily as possible
function mycompinit() {
  # zsh
  local ZSHCOMPLETIONS="$HOME/.config/zsh/completions"
  mkdir -p "$ZSHCOMPLETIONS"
  if (( $+commands[gh] )) && [[ ! -r "${ZSHCOMPLETIONS}/_gh" || "$( whence -p gh  )" -nt "${ZSHCOMPLETIONS}/_gh" ]]; then
    command gh completion -s zsh > "${ZSHCOMPLETIONS}/_gh"
  fi
  if (( $+commands[mise] )) &&[[ ! -r "${ZSHCOMPLETIONS}/_mise" || "$( whence -p mise  )" -nt "${ZSHCOMPLETIONS}/_mise" ]]; then
    mise completion zsh > "${ZSHCOMPLETIONS}/_mise"
  fi
  if (( $+commands[deno] )) &&[[ ! -r "${ZSHCOMPLETIONS}/_deno" || "$( whence -p deno  )" -nt "${ZSHCOMPLETIONS}/_deno" ]]; then
    deno completions zsh > "${ZSHCOMPLETIONS}/_deno"
  fi
  if (( $+commands[poetry] )) && [[ ! -r "${ZSHCOMPLETIONS}/_poetry" || "$( whence -p poetry  )" -nt "${ZSHCOMPLETIONS}/_poetry" ]]; then
    poetry completions zsh > "${ZSHCOMPLETIONS}/_poetry"
  fi
  autoload -Uz compinit && compinit

  # bash
  autoload -U +X bashcompinit && bashcompinit
  local BASHCOMPLETIONS="$HOME/.config/bash/completions"
  mkdir -p "$BASHCOMPLETIONS"

  if [[ ! -r "${BASHCOMPLETIONS}/az.completion" || "$( whence -p az )" -nt "${BASHCOMPLETIONS}/az.completion" ]]; then
    curl -sL 'https://raw.githubusercontent.com/Azure/azure-cli/dev/az.completion' -o "${BASHCOMPLETIONS}/az.completion"
  fi
  fd . "$BASHCOMPLETIONS" --exclude '*.zwc' --type file | while read -r f; do
    source "$f"
  done

  complete -C "$( whence -p aws_completer )" aws
}

zsh-defer mycompinit

# cleanup
zsh-defer unset -f source
