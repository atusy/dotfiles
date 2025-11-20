is_darwin() {
  [[ $OSTYPE == darwin* ]]
}

fish_needs_login() {
  # on macOS avoid using login shell as it makes strange PATH
  [[ -o login ]] && ! is_darwin
}

on_shell() {
  local pcomm
  if is_darwin; then
    # BSD ps
    pcomm=$(ps -p $PPID -o comm=)
  else
    # GNU ps
    pcomm=$(ps --no-header --pid=$PPID --format=comm)
  fi
  [[ $(basename "$pcomm") =~ ^(.*/)?(ba|fi|xon|z)sh$ ]]
}

if [[ ! -o interactive ]] || (( ! $+commands[fish] )) || on_shell; then
  source "$HOME/.config/zsh/config/default.zsh"
  return
fi

# try fish on tmux
# don't exec, allows detaching and returning to fish
if (( $+commands[tmux] )) && [[ -z "$TMUX" ]] && [[ "$TERM" != screen.* ]] && ! tmux has-session; then
  if fish_needs_login; then
    tmux new-session "fish --login"
  else
    tmux new-session fish
  fi
fi

# if tmux is unavaailable or exited, exec fish
# feel free to exec we can always enter zsh intentionally
if fish_needs_login; then
  exec fish --login
else
  exec fish
fi
