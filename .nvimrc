lua << EOF
local chezmoi = vim.api.nvim_exec('pwd', true)
vim.api.nvim_create_autocmd('BufWritePost', {
  callback = function(args)
    if vim.startswith(args.file, '.git/') then return end
    vim.notify('!chezmoi apply')
    vim.cmd('!chezmoi apply')
    if vim.startswith(args.file, 'dot_config/nvim') then
      vim.notify(':source $MYVIMRC')
      vim.cmd('source $MYVIMRC')
    end
  end,
  group = vim.api.nvim_create_augroup('atusy-chezmoi', {}),
  pattern = chezmoi .. '/*',
})
EOF
