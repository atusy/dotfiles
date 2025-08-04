function __abbr-token-base
  commandline --cut-at-cursor | read --tokenize --list --local tokens_left

  set -l idx ( echo $tokens_left[-1] | string sub --start 2 )

  # idxが負ならカーソル位置からidx個手前のトークンを展開
  if echo "_$idx" | string match -q -r "^_[-]"
    set -l idx2 ( math "$idx - 1" )
    echo $tokens_left[$idx2]
    return 0
  end

  commandline | read --tokenize --list --local tokens_all 

  # idxが+ではじまる正数ならカーソル位置からidx個手後のトークンを展開
  if echo "_$idx" | string match -q -r "^_[+]"
    set -l base ( count $tokens_left )
    set -l idx2 ( math "$base + $idx" )
    echo $tokens_all[$idx2]
    return 0
  end

  # idxに正負の符号がない場合は全トークンからsliceする
  echo $tokens_all[$idx]
end

function __abbr-token
  __abbr-token-base | string escape
end
