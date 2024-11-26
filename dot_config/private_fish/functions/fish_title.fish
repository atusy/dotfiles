function fish_title
  if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
    set -l ssh
    set -q SSH_TTY
    and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"

    set -l wd
    if set -l gwd (git rev-parse --show-toplevel 2> /dev/null)
      set -l n (dirname "xx$gwd" | string length) # add extra characters to generate start index
      set wd (string sub --start $n $PWD)
    else
      set wd (basename $PWD)
    end

    echo -- $ssh $wd
  end
end

