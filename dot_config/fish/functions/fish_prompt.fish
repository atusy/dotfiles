# originally comes from
# /usr/share/fish/functions/fish_git_prompt.fish

set -g fish_color_cwd magenta
set -g __fish_git_prompt_showcolorhints 1
set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_showupstream 1
set -g ___fish_git_prompt_char_dirtystate '*'
set -g ___fish_git_prompt_char_invalidstate '#'
set -g ___fish_git_prompt_char_stagedstate '+'
set -g ___fish_git_prompt_char_stashstate '$'
set -g ___fish_git_prompt_char_stateseparator '|'
set -g ___fish_git_prompt_char_untrackedfiles '?'
set -g ___fish_git_prompt_char_upstream_ahead '↑'
set -g ___fish_git_prompt_char_upstream_behind '↓'
set -g ___fish_git_prompt_char_upstream_diverged '<>'
set -g ___fish_git_prompt_char_upstream_equal '='
set -g ___fish_git_prompt_char_upstream_prefix ''

# A new prompt gets its own directory, so a worker from a previous prompt
# cannot publish into it. Repainting does not start another round of workers.
set -g __prompt_async_source (path resolve (status filename))

function __prompt_async_start --on-event fish_prompt
    set -g __prompt_async_started
    set -e __prompt_status_bold_flag
    __prompt_async_cleanup
    set -g __prompt_async_dir (command mktemp -d)
    or return
    set -g __prompt_async_pwd "$PWD"

    for name in PROMPT_KUBEINFO __kubeinfo_cmd __kubeinfo_cache
        if set -q $name
            set -fx $name $$name
        end
    end

    set -l fish_executable (status fish-path)
    for segment in git kube
        $fish_executable --no-config -c '
            set -g fish_function_path $argv[5..]
            source "$argv[1]"
            __prompt_async_render $argv[2..4]
        ' -- "$__prompt_async_source" "$__prompt_async_dir" $segment $fish_pid $fish_function_path </dev/null >/dev/null 2>&1 &
        disown $last_pid
    end
end

function __prompt_async_render --argument-names dir segment parent
    if test "$segment" = git
        __prompt_git_title >"$dir/title.tmp"
        __prompt_async_publish "$dir/title" $parent
    end

    begin
        switch $segment
            case git
                printf '%s' (fish_vcs_prompt)
            case kube
                __prompt_kubeinfo
        end
    end >"$dir/$segment.tmp"
    __prompt_async_publish "$dir/$segment" $parent
end

function __prompt_async_publish --argument-names file parent
    test -s "$file.tmp"
    and command mv -- "$file.tmp" "$file"
    and kill -s USR1 $parent
end

function __prompt_git_title
    if set -l root (git rev-parse --show-toplevel 2>/dev/null)
        set -l parent (path dirname -- "$root")
        set -l prefix (string replace -r '/$' '' -- "$parent")/
        set -l prefix_length (string length -- "$prefix")
        if test (string sub --length $prefix_length -- "$PWD") = "$prefix"
            string sub --start (math $prefix_length + 1) -- "$PWD"
            return
        end
    end
    path basename -- "$PWD"
end

function __prompt_async_repaint --on-signal USR1
    commandline -f repaint 2>/dev/null
end

function __prompt_async_cleanup --on-event fish_exit
    if set -q __prompt_async_dir[1]
        command rm -rf -- "$__prompt_async_dir"
        set -e __prompt_async_dir
    end
end

function __prompt_kubeinfo
    set -l prompt_kubeinfo
    if set -l kubeinfo ( get_kubeinfo | string split " " ); and test -n "$kubeinfo[1]"
        set -l normal (set_color normal)
        if test "$PROMPT_KUBEINFO" = false
            set prompt_kubeinfo " ☸️" # At least notify that kubeinfo is available
        else
            test -z "$kubeinfo[2]"; and set kubeinfo[2] N/A
            set prompt_kubeinfo " ["(set_color cyan){$kubeinfo[1]}{$normal}":"(set_color cyan){$kubeinfo[2]}{$normal}"]"
        end
    end

    printf '%s' "$prompt_kubeinfo"
end

function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l prompt_suffix '$'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set prompt_suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    if status is-interactive; and not set -q __prompt_async_started
        __prompt_async_start
    end
    if not status is-interactive; or not set -q __prompt_status_bold_flag
        set -g __prompt_status_bold_flag --bold
        set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
        if test $__fish_prompt_status_generation = $status_generation
            set __prompt_status_bold_flag
        end
        set __fish_prompt_status_generation $status_generation
    end
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $__prompt_status_bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    set -l prompt_user
    if test -n "$SSH_CLIENT"
        set prompt_user (prompt_login)" "
    end

    set -l color_file (set_color $color_cwd)
    set -l slash "$(set_color "#d2691e")/$color_file"
    set -l prompt_cwd $color_file(prompt_pwd -D 8 | string replace -ar "/" $slash)$normal
    set -l prompt_vcs
    set -l prompt_kubeinfo
    if status is-interactive
        if set -q __prompt_async_dir[1]; and test -f "$__prompt_async_dir/git"
            read -z prompt_vcs <"$__prompt_async_dir/git"
        end
        if set -q __prompt_async_dir[1]; and test -f "$__prompt_async_dir/kube"
            read -z prompt_kubeinfo <"$__prompt_async_dir/kube"
        end
    else
        set prompt_vcs (fish_vcs_prompt)
        set prompt_kubeinfo (__prompt_kubeinfo)
    end

    echo -s $prompt_user $prompt_cwd $prompt_vcs $prompt_kubeinfo " " $prompt_status
    echo -n $prompt_suffix" "$normal
end
