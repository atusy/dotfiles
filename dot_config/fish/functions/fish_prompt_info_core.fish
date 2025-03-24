set -g fish_color_cwd magenta

function fish_prompt_info_core
    set -l normal (set_color normal)

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
    end

    set -l prompt_user
    if test -n "$SSH_CLIENT"
      set prompt_user (prompt_login)" "
    end

    set -l color_file (set_color $color_cwd)
    set -l slash "$(set_color "#d2691e")/$color_file"
    set -l prompt_cwd $color_file(prompt_pwd -D 8 | string replace -ar "/" $slash)$normal

    echo -s -n $prompt_user $prompt_cwd
end
