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

## Neovim


# queries/markdown/locals.scm

Required by nvim-treehopper

``` bash
curl -fsSL https://raw.githubusercontent.com/MDeiml/tree-sitter-markdown/330ecab87a3e3a7211ac69bbadc19eabecdb1cca/src/node-types.json -o /tmp/markdown.json
cat /tmp/markdown.json | jq 'map(.type)' | head -n -1 | tail -n +2 | sed -E -e 's/\s+"//' -e 's/",?$//' | grep '^[a-zA-Z]' | sort | sed -E -e 's/(.*)/(\1) @\1/' > ~/.config/nvim/queries/markdown/locals.scm
```
