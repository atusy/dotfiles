# Use fish as if default shell https://wiki.archlinux.org/title/Fish
# I do not chsh in case fish is not installed or installed to paths not in /etc/shells
if [[ $- == *i* && $- != *c* ]] && command -v fish &>/dev/null && [[ $(ps --no-header --pid=$PPID --format=comm) =~ (ba|fi|xon|z)sh ]]; then
  # try fish on tmux
  # don't exec, allows detaching and returning to fish
  if command -v tmux &>/dev/null && test -z "$TMUX" && [[ $TERM != screen.* ]]; then
    if shopt -q login_shell; then
      tmux new-session "fish --login"
    else
      tmux new-session fish
    fi
  fi

  # if tmux is unavaailable or exited, exec fish
  # feel free to exec we can always enter bash by intentionally
  if shopt -q login_shell; then
    exec fish --login
  else
    exec fish
  fi
fi
