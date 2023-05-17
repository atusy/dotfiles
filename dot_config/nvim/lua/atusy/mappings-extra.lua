local set_palette = require("atusy.utils").set_palette

--[[ window ]]
set_palette("n", "window: equalize horizontally", "<Cmd>hroizontal wincmd =<CR>")
set_palette("n", "window: equalize vertically", "<Cmd>vertical wincmd =<CR>")

--[[ clipboard ]]
set_palette("n", "clipboard: copy cwd", "<Cmd>let @+=getcwd()<CR>")
set_palette("n", "clipboard: copy abs path of of %", '<Cmd>let @+=expand("%:p")<CR>')
set_palette("n", "clipboard: copy abs path of dirname of %", '<Cmd>let @+=expand("%:p:h")<CR>')

--[[ treesitter ]]
set_palette("n", "treesitter: inspect tree", function()
  (vim.treesitter.inspect_tree or vim.treesitter.show_tree)()
end)
set_palette(
  "n",
  "redraw!",
  [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
  { desc = "with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter" }
)

--[[ lsp ]]
set_palette("n", "lsp: list attached clients", function()
  local res = {}
  for _, c in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
    table.insert(res, tostring(c.id) .. ":" .. c.config.name)
  end
  print(table.concat(res, ", "))
end)
set_palette("n", "lsp: restart attached clients", function()
  vim.lsp.stop_client(vim.lsp.get_active_clients({ bufnr = 0 }))
  vim.cmd("edit!")
end)
