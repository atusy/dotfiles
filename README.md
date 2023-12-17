# dotfiles

Version controlled by chezmoi

## Git

### Git Hooks

`executable_*` are copied from `template.bash`

``` bash
man githooks | grep -E '^\s{3}[a-z]' | sed -Ee 's/\s+//' | while read -r hook
do
  cp "dot_config/git/hooks/template.bash" "dot_config/git/hooks/$hook"
done
```

## Vim/Neovim

- [爆速で起動する Neovim を作る](https://qiita.com/delphinus/items/fb905e452b2de72f1a0f)
- [nvim-lspの設定をlsp-handlerでカスタマイズする](https://zenn.dev/nnsnico/articles/customize-lsp-handler)
- [NeovimのLSPで誰にどうして怒られたのかを確認するための設定](https://dev.classmethod.jp/articles/eetann-change-neovim-lsp-diagnostics-format/)
