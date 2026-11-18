if ! status is-interactive
    if set -q NVIM_EX_COMPLETION
        # Ex-command aliases for Neovim shell completion
        alias Gin=git
        alias GinBuffer=git
        alias lmake=make
    end
    return
end

# ---------------------
# for interactive shell
# ---------------------

# @fish-lsp-disable-next-line 2003
set -U fish_greeting

if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

source_hook mise activate fish
source_hook direnv hook fish
source_hook zoxide init fish --no-cmd

if type -q brew
    __setup-brew brew
else
    for brew in "$HOME/.linuxbrew/bin/brew" /opt/homebrew/bin/brew
        if test -x $brew
            __setup-brew $brew
        end
    end
end

abbr -a ping 'ping -c 5'
abbr -a vim nvim
abbr -a --set-cursor math 'math "%"'
abbr -a ll 'eza --long --group --time-style=long-iso'
abbr -a checkout-detach --function __abbr-checkout-detach --position anywhere
abbr -a pick-token --regex ',[-+]?[0-9]+' --function __abbr-pick-token --position anywhere

bind \t complete-and-search-if-not-empty
bind \cx\cf complete-path-with-fzf
bind \cr set_commandline_from_suggestions
bind \cc cancel-commandline

if not string match -q -r '(^| )--bind=ctrl-y:replace-query($| )' -- "$FZF_DEFAULT_OPTS"
    set -gx FZF_DEFAULT_OPTS (string join ' ' -- $FZF_DEFAULT_OPTS --bind=ctrl-y:replace-query)
end

if set -q NVIM
    function _nvim-preexec --on-event fish_preexec --wraps __nvim-preexec
        __nvim-preexec $argv
    end
    if type -q nvr
        set -gx EDITOR __nvr-tabedit
    end
else
    set -gx EDITOR nvim
end

update_completion gh completion -s fish
update_completion mise completion fish
update_completion deno completions fish
update_completion task --completion fish
update_completion kubectl completion fish

set_gh_config_dir

set -l local_config (status dirname)/local.fish
if test -f $local_config
    source $local_config
end
