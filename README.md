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

