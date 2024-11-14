# ref: https://github.com/kyoh86/dotfiles/blob/5fdef4f60889e2a77998b3539911d0a9814c7db8/zsh/part/nvim_cmd.zsh
function __nvim-preexec
  set -l buf "$argv[1]"
  set -l matches (string match --groups-only --regex "^\s*(\S*)" "$buf")
  set -l cmd "$matches[1]"

  # ignore if not likely a Ex-command
  if not string match --quiet --regex "^:" "$cmd"; or type --quiet "$cmd"
    return
  end

  # evaluate as Ex-command
  set -l buf2 (echo "$buf" | base64)
  set -l res (
    nvim --server $NVIM --headless --remote-expr "execute(v:lua.vim.base64.decode(\"$buf2\"))" | tail -n +2
  )
  echo "$res"

  # temporarily define function to avoid "not found" error
  eval "function $cmd; functions -e \"$cmd\"; end"
end
