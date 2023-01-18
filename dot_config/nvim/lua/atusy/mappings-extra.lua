local set_palette = require('utils').set_palette

--[[ clipboard ]]
set_palette('n', 'clipboard cwd', '<Cmd>let @+=getcwd()<CR>')
set_palette('n', 'clipboard abs path of of %', '<Cmd>let @+=expand("%:p")<CR>')
set_palette('n', 'clipboard abs path of dirname of %', '<Cmd>let @+=expand("%:p:h")<CR>')

--[[ treesitter ]]
set_palette('n', 'treesitter show tree', function() vim.treesitter.show_tree() end)
