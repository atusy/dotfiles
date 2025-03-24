# originally comes from
# /usr/share/fish/functions/fish_git_prompt.fish

# configurations
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

function fish_prompt --description 'Write out the prompt'
    set -l varname_prompt_extra (fish_prompt_info_extra_async)

    set -l normal (set_color normal)

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -q fish_color_status
    or set -g fish_color_status red
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    # Change prompt suffix when on root
    set -l prompt_suffix '$'
    if functions -q fish_is_root_user; and fish_is_root_user
        set prompt_suffix '#'
    end

    # Use below for synchronous behavior
    # echo -s (fish_prompt_info_core) (fish_prompt_info_extra) " " $prompt_status
    echo -s (fish_prompt_info_core) $$varname_prompt_extra " " $prompt_status
    echo -n $prompt_suffix" "$normal
end
