vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/impatient')
local ok, impatient = pcall(require, 'impatient')
if ok then
  impatient.enable_profile()
else
  vim.notify(ok, vim.log.levels.ERROR)
end
require('atusy')
