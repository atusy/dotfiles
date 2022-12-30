local chezmoi = vim.api.nvim_exec('pwd', true)
local group = vim.api.nvim_create_augroup('nvimrc-chezmoi', {})
vim.api.nvim_create_autocmd('VimLeave', {
  callback = function(args)
    if vim.startswith(args.file, '.git/') then return end
    vim.cmd('!chezmoi apply')
  end,
  group = group,
  pattern = chezmoi .. '/*',
})
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = '*.lua',
  group = group,
  callback = function() pcall(vim.lsp.buf.format) end,
})
