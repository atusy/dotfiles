function on_fish {
  local pcomm
  if [[ $OSTYPE == darwin* ]]; then
    # BSD ps
    pcomm=$(ps -p $PPID -o comm=)
  else
    # GNU ps
    pcomm=$(ps --no-header --pid=$PPID --format=comm)
  fi
  [[ $(basename "$pcomm") == fish ]]
}

if [[ ! -o interactive ]] || (( ! $+commands[fish] )) || on_fish; then
  source "$HOME/.config/zsh/config/default.zsh"
  return
fi

# try fish on tmux
# don't exec, allows detaching and returning to fish
if (( $+commands[tmux] )) && [[ -z "$TMUX" ]] && [[ "$TERM" != screen.* ]]; then
  if [[ -o login ]]; then
    tmux new-session -c "fish --login"
  else
    tmux new-session -c fish
  fi
fi

# if tmux is unavaailable or exited, exec fish
# feel free to exec we can always enter zsh intentionally
if [[ -o login ]]; then
  exec fish --login
else
  exec fish
fi
