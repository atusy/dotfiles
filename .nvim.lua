local group = vim.api.nvim_create_augroup("nvimrc-chezmoi", {})
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function(args)
    vim.system({ "chezmoi", "apply" }):wait()
  end,
  group = group,
})
