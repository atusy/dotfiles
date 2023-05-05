local set_palette = require("atusy.utils").set_palette

--[[ window ]]
set_palette("n", "window: horizontally equalize", "<Cmd>hroizontal wincmd =<CR>")
set_palette("n", "window: vertically equalize", "<Cmd>vertical wincmd =<CR>")

--[[ clipboard ]]
set_palette("n", "clipboard cwd", "<Cmd>let @+=getcwd()<CR>")
set_palette("n", "clipboard abs path of of %", '<Cmd>let @+=expand("%:p")<CR>')
set_palette("n", "clipboard abs path of dirname of %", '<Cmd>let @+=expand("%:p:h")<CR>')

--[[ treesitter ]]
set_palette("n", "treesitter inspect tree", function()
  (vim.treesitter.inspect_tree or vim.treesitter.show_tree)()
end)
set_palette(
  "n",
  "redraw!",
  [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
  { desc = "with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter" }
)
