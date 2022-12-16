local scorpeon = vim.fn.stdpath('cache') .. '/scorpeon/extensions'
local vscode = vim.fn.stdpath('cache') .. 'vscode'
vim.g.scorpeon_extensions_path = { scorpeon, vscode .. '/extensions' }
return {
  deps = {
    'uga-rosa/scorpeon.vim',
    { 'microsoft/vscode', merged = false, opt = 1, path = vscode },
    { 'sumneko/vscode-lua', merged = false, opt = 1, path = scorpeon .. '/lua' },
  },
  setup = function() end
}
