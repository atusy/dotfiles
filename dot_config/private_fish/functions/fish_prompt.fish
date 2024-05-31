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

set -g __kube_config
set -g __kube_ctx
set -g __kube_ns
set -g __kube_ts 0

function __update_kubeinfo
  # normalize KUBECONFIG
  if set -qx KUBECONFIG; and string match -q -r '^~/' "$KUBECONFIG"
    eval "set -gx KUBECONFIG $KUBECONFIG"
  end

  # update if KUBECONFIG path has changed
  set -l __kube_config_default ~/.kube/config
  if set -qx KUBECONFIG; and test -n "$KUBECONFIG"
    if not test "$__kube_config" = "$KUBECONFIG"
      set __kube_config "$KUBECONFIG"
      set __kube_ts 0
      set __kube_ctx
      set __kube_ns
    end
  else if not test "$__kube_config" = "$__kube_config_default"
    set __kube_config "$__kube_config_default"
    set __kube_ts 0
    set __kube_ctx
    set __kube_ns
  end

  # abort if KUBECONFIG is not found
  if not test -f $__kube_config
    return 1
  end

  # update if KUBECONFIG content has updated
  set -l ts ( stat -c "%Y" "$__kube_config" )
  if test "$ts" -eq "$__kube_ts"
    return 0
  end
  set __kube_ts $ts

  # get ctx
  set __kube_ctx (kubectl config current-context 2>/dev/null)
  test -z "$__kube_ctx"; and
    return 1
  end

  # get ns
  set __kube_ns (kubectl config view -o "jsonpath={.contexts[?(@.name==\"$__kube_ctx\")].context.namespace}")
  test -z $__kube_ns; and set __kube_ns 'N/A'
end

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

    __update_kubeinfo
    if test -n "$__kube_ctx"
      echo -n -s " [" (set_color cyan) $__kube_ctx $normal ":" (set_color cyan) $__kube_ns $normal "]"
    end
    echo -s $normal " "$prompt_status
    echo -n -s $suffix " " $normal
end
