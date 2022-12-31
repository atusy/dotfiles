local scorpeon = vim.fn.stdpath('cache') .. '/scorpeon/extensions'
local vscode = vim.fn.stdpath('cache') .. 'vscode'
vim.g.scorpeon_extensions_path = { scorpeon, vscode .. '/extensions' }
return {
  { 'uga-rosa/scorpeon.vim',
    enabled = false,
    dependencies = {
      { 'microsoft/vscode', enabled = false },
      { 'sumneko/vscode-lua', enabled = false },
    }
  }
}
