# History
HISTFILE=~/.zsh_history
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
zstyle ':completion:*'              list-colors "${(s.:.)LS_COLORS}"
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

## Enable completions
zstyle ':compinstall' filename "$HOME/.zshrc"
autoload -Uz compinit
compinit

# Alias
# nnn with quitcd (/usr/share/nnn/quitcd.bash_zsh)
n ()
  {
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
      echo "nnn is already running"
      return
    fi

    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # To cd on quit only on ^G, remove the "export" as in:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    # NOTE: NNN_TMPFILE is fixed, should not be modified
    NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    nnn -de "$@"

    if [ -f "$NNN_TMPFILE" ]; then
      . "$NNN_TMPFILE"
      if command -v zoxide > /dev/null; then
        zoxide add "$( pwd )"
      fi
      rm -f "$NNN_TMPFILE" > /dev/null
    fi
  }

if command -v zoxide > /dev/null; then
  if [[ "$(command -v zi)" =~ "^alias .+" ]]; then
    unalias zi
  fi
  eval "$(zoxide init zsh)"
fi

if command -v htop > /dev/null; then
  alias top='htop'
fi
if command -v duf > /dev/null; then
  alias df='duf'
else
  alias df='df -h'
fi
if command -v procs > /dev/null; then
  alias ps='procs'
fi
if command -v gdu > /dev/null; then
  alias du='gdu'
fi
if command -v exa > /dev/null; then
  alias ls='exa -l --icons --time-style=iso --color=always'
fi
if command -v bat > /dev/null; then
  alias cat='bat'
fi
if command -v wget2 > /dev/null
then
  alias wget='wget2 -c' # resumable
elif command -v wget > /dev/null; then
  alias wget='wget -c' # resumable
fi
if command -v nvim > /dev/null; then
  alias vim='nvim'
fi
if command -v xdg-open > /dev/null; then
  function open() {
    xdg-open "$@" 2>/dev/null
  }
fi

alias gd='cd-gitroot'

function gi() {
  # fuzzy cd in git project.
  # Primary choices come from zoxide regardless of gitignore
  # Secondary choices come from git ls-files respecting gitignore
  local COLOR_GI_PRIMARY="${COLOR_GI_PRIMARY:-32}"
  local ROOT="$( git rev-parse --show-toplevel )"
  if [[ "$ROOT" == "" ]]; then return 1; fi
  local CHOICE="$({
    # Redirect choices to stderr and turn back to stdout to reduce codes
    PRIMARY="$(
      for _z in $( zoxide query --list | grep -F "$ROOT" )
      do
        _z="${_z#${ROOT}/}"
        echo "$_z"
        echo -e "\e[${COLOR_GI_PRIMARY}m${_z}\e[m" 1>&2
      done
    )"
    cd "$ROOT"
    SECONDARY="$( git ls-files | xargs dirname | sort | uniq )"
    echo -e "${SECONDARY}\n.\n${PRIMARY}\n${PRIMARY}" | sort | uniq --unique 1>&2
  } 2>&1 | fzf-tmux --ansi )"
  local TARGET="${ROOT}/${CHOICE#${ROOT}}"
  zoxide add "$TARGET" 
  cd "$TARGET" 
}

function lf() {
  # fuzzy ls and output selections or all to stderr
  # ls can be an alias but not a function
  # result goes only to stderr, but also to stdout when pipe follows

  # prep
  local LIST="$( ls -l --color=always "$@" )"
  local LIST_BW="$(
    declare -a ARGS=( "-1" )
    for a in $@; do
      if [[ "$a" == "-l" ]] || [[ "$a" == "--long" ]];
      then
        continue
      fi
      ARGS+=( $a )
    done
    echo "$ARGS" | xargs $( whence ls | awk '{ print $1 }' )
  )"

  # fzf
  local SEL_TXT="$(
    echo "$LIST" \
      | command cat -n \
      | command fzf-tmux \
          --ansi --multi --with-nth 2.. \
          --preview "echo \"$LIST_BW\" | sed -n \"\$( ( for i in {+n}; do echo \$(( i + 1 )); done ) | tr '\n' 'p' | sed -e 's/p/p;/g' )\"" \
          --bind 'ctrl-p:toggle-preview'
  )"
  local SEL_NUM="$( echo "$SEL_TXT" | awk '{print $1}' | tr '\n' 'p' | sed -e 's/p/p;/g' )"

  # output
  echo "$LIST" | sed -n $SEL_NUM 1>&2
  if [[ ! -t 1 ]]
  then
    echo "$LIST_BW" | sed -n $SEL_NUM
  fi
}

if command -v pyenv >/dev/null; then eval "$(pyenv init -)"; fi
function pyset() {
  local PYSET_IMPLICIT_GLOBAL=${PYSET_IMPLICIT_GLOBAL:-true}
  local PYSET_MAX_HEIGHT=${PYSET_MAX_HEIGHT:-10}
  local SCOPE="${1:-local}"
  local PATTERN="${2:-${PYSET_PATTERN:-^[0-9]+\.}}"
  local TARGET="$(
    CANDIDATES="$(
      pyenv install --list \
        | awk '{ print $1 }' \
        | command grep -E "$PATTERN"
      [[ -f .python-version ]] && echo "$( cat .python-version ) (.python-version)"
    )"
    HEIGHT="$(
      N="$(echo "$CANDIDATES" | wc -l)"
      echo "$(( $N + 2 ))\n${PYSET_MAX_HEIGHT}" \
        | sort -nu \
        | head -n 1
    )"
    echo "$CANDIDATES" | command fzf --height="$HEIGHT" --tac | awk '{ print $1 }'
  )"
  if [[ "$TARGET" == "" ]]
  then
    if ! $PYSET_IMPLICIT_GLOBAL
    then
      return 1
    fi
    echo "Using global python..." 1>&2
    TARGET="$( python --version | sed -E -e 's/^Python\s+//' )"
  fi
  pyenv install --skip-existing "$TARGET"
  pyenv "$SCOPE" "$TARGET"
  pyenv "$SCOPE" 
}

function l2tp() {
  sudo sysctl -p
  sudo ipsec auto --${1:-up} L2TP-PSK
}

function vpn() {
  echo "${1:-c} vpn01" | sudo tee /var/run/xl2tpd/l2tp-control
}

function via() {
  sudo ip route ${2:-add} 192.168.1.21 via 192.168.1.$1 dev ppp0
}

# Options
ZSH_AUTOSUGGEST_USE_ASYNC=1

# zeno
if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  # ^r fails due to lazy key bindigs by zsh-vi-mode
  bindkey '^h' zeno-history-selection
fi

# Vi modes (`jeffreytse/zsh-vi-mode` instead of `bindkey -v`)
KEYTIMEOUT=5

## Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]
  then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]
  then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

## Use beam shape cursor on startup.
echo -ne '\e[5 q'

## Use beam shape cursor for each new prompt.
preexec() {
   echo -ne '\e[5 q'
}

[[ -f "$HOME/.config/zsh/local.zshrc" ]] && source "$HOME/.config/zsh/local.zshrc"

