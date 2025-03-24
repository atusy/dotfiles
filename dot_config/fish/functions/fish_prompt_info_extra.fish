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

function fish_prompt_info_extra --description 'Write out the prompt'
    set -l normal (set_color normal)
    set -l prompt_vcs (fish_vcs_prompt)

    set -l prompt_kubeinfo
    set -l kubeinfo ( get_kubeinfo | string split " " )
    if test -n "$kubeinfo[1]"
      test -z "$kubeinfo[2]"; and set kubeinfo[2] "N/A"
      set prompt_kubeinfo " ["(set_color cyan){$kubeinfo[1]}{$normal}":"(set_color cyan){$kubeinfo[2]}{$normal}"]"
    end

    echo -s -n $prompt_vcs $prompt_kubeinfo " " $prompt_status
end
