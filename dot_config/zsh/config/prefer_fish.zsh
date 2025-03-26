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

if (( ! $+commands[tmux] )) || [[ -n "$TMUX" ]] || [[ "$TERM" == screen.* ]]; then
  # Not using tmux (either unavailable, already inside, or TERM indicates screen)
  # Launch fish directly, replacing the zsh process
  if [[ -o login ]]; then
    # If it's a login shell, exec fish as login shell
    exec fish --login
  else
    # Otherwise, exec regular fish shell
    exec fish
  fi
  return
fi

# Launch tmux with fish
# Don't exec, allows detaching and returning to zsh
if [[ -o login ]]; then
  # If it's a login shell, start tmux session with fish as login shell
  tmux -c "fish --login"
else
  # Otherwise, start tmux session with regular fish shell
  tmux -c fish
fi

# after quitting tmux, fallback to customized zsh
source "$HOME/.config/zsh/config/default.zsh"
