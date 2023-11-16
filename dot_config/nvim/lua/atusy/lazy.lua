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

local lazy_all = true
function M.load_all()
  if lazy_all then
    pcall(require("lazy").load, { plugins = require("lazy").plugins() })
    lazy_all = false
  end
end

return M
