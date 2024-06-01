# originally comes from
# /usr/share/fish/functions/fish_git_prompt.fish

set -g fish_color_cwd yellow
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

function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    if ! test -z $SSH_CLIENT
      echo -n -s (prompt_login)' '
    end
    echo -n -s (set_color $color_cwd) (prompt_pwd -D 3) $normal (fish_vcs_prompt)

    set -l kubeinfo ( get_kubeinfo2 | string split ' ' ) # faster than kubeinfo
    if test -n "$kubeinfo[1]"
      test -z $kubeinfo[2]; and set kubeinfo[2] 'N/A'
      echo -n -s " [" (set_color cyan) $kubeinfo[1] $normal ":" (set_color cyan) $kubeinfo[2] $normal "]"
    end
    echo -s $normal " "$prompt_status
    echo -n -s $suffix " " $normal
end
