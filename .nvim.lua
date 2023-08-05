local group = vim.api.nvim_create_augroup("nvimrc-chezmoi", {})
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function(args)
    vim.system({ "chezmoi", "apply" }):wait()
  end,
  group = group,
})
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = "*.lua",
  group = group,
  callback = function()
    pcall(vim.lsp.buf.format)
  end,
})
