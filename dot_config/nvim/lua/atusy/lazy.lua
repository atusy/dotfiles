local M = {}

function M.install(lazypath)
  local cmd = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  return cmd:wait()
end

return M
