set -l _fish_title_pwd
set -l _fish_title_wd

function fish_title
  if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
    set -l ssh
    set -q SSH_TTY
    and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"

    if test "$_fish_title_pwd" != "$PWD"
      set _fish_title_pwd $PWD
      if set -l gwd (git rev-parse --show-toplevel 2> /dev/null)
        set -l n (dirname "xx$gwd" | string length) # add extra characters to generate start index
        set _fish_title_wd (string sub --start $n $PWD)
      else
        set _fish_title_wd (basename $PWD)
      end
    end

    echo -- $ssh $_fish_title_wd
  end
end

