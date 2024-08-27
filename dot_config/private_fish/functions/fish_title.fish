function fish_title
  if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
    set -l ssh
    set -q SSH_TTY
    and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"
    echo -- $ssh ( basename $PWD )
  end
end

