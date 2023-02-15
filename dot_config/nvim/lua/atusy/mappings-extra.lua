local set_palette = require("atusy.utils").set_palette

--[[ clipboard ]]
set_palette('n', 'clipboard cwd', '<Cmd>let @+=getcwd()<CR>')
set_palette('n', 'clipboard abs path of of %', '<Cmd>let @+=expand("%:p")<CR>')
set_palette('n', 'clipboard abs path of dirname of %', '<Cmd>let @+=expand("%:p:h")<CR>')

--[[ treesitter ]]
set_palette('n', 'treesitter show tree', function() vim.treesitter.show_tree() end)
set_palette(
  'n', 'redraw!', [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
  { desc = 'with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter' }
)
