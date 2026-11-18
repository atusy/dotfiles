function fish_title
    if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
        set -l ssh
        set -q SSH_TTY
        and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"

        if test "$_fish_title_pwd" != "$PWD"
            set -g _fish_title_pwd "$PWD"
            set -g _fish_title_wd (path basename -- "$PWD")
        end
        if test "$__prompt_async_pwd" = "$PWD"; and set -q __prompt_async_dir[1]; and test -f "$__prompt_async_dir/title"
            read -g _fish_title_wd <"$__prompt_async_dir/title"
        end

        echo -- $ssh $_fish_title_wd
    end
end
