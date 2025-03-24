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

# variables for async behavior
set -l varname_prefix "___atusy_"$fish_pid"_"
set -l varname_prompt_extra $varname_prefix"prompt_extra"
set -U $varname_prompt_extra
set -l varname_prompt_request $varname_prefix"prompt_request"
set -U $varname_prompt_request false

function __clean_atusy_vars --on-event fish_exit --inherit-variable varname_prefix
  # erase universal variable created on this process
  set -e -U (set -n -U | string match -r "^"$varname_prefix)

  # erase orphant universal variable
  set -l pids
  set -n -U | string match -r "^___atusy_[0-9]+_" | sort -u | string match -r "[0-9]+" | while read -l pid
    set -l comm (ps -p $pid -o comm=)
    if test "$comm" != "fish"
      set --append pids $pid
    end
  end
  if test -z "$pids"
    return
  end
  set -l pat "^___atusy_("(string join "|" $pids)")_.*"
  set -e -U (set -n -U | string match -r $pat)
end

function __update_atusy_prompt_extra --inherit-variable varname_prompt_extra --inherit-variable varname_prompt_request
  fish -c "
    set -U $varname_prompt_extra (fish_prompt_info_extra)
    set -U $varname_prompt_request true
  " &
end

function __repaint_prompt --on-variable $varname_prompt_extra
  set -U --no-event $varname_prompt_request false
  commandline -f repaint
end

function fish_prompt --description 'Write out the prompt' --inherit-variable varname_prompt_extra
    __update_atusy_prompt_extra

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

    echo -s (fish_prompt_info_core) $$varname_prompt_extra " " $prompt_status
    echo -n $prompt_suffix" "$normal
end
