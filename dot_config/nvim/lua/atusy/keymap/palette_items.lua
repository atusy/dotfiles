return {
  --[[ window ]]
  { mode = "n", lhs = "window: equalize horizontally", rhs = "<Cmd>hroizontal wincmd =<CR>" },
  { mode = "n", lhs = "window: equalize vertically", rhs = "<Cmd>vertical wincmd =<CR>" },
  --[[ clipboard ]]
  { mode = "n", lhs = "clipboard: cwd", rhs = "<Cmd>let @+=getcwd()<CR>" },
  { mode = "n", lhs = "clipboard: abs path of %", rhs = '<Cmd>let @+=expand("%:p")<CR>' },
  { mode = "n", lhs = "clipboard: abs path of dirname of %", rhs = '<Cmd>let @+=expand("%:p:h")<CR>' },
  --[[ treesitter ]]
  {
    mode = "n",
    lhs = "treesitter: inspect tree",
    rhs = function()
      vim.treesitter.inspect_tree()
    end,
  },
  {
    mode = "n",
    lhs = "redraw!",
    rhs = [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
    opts = {
      desc = "with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter",
    },
  },

  --[[ lsp ]]
  {
    mode = "n",
    lhs = "lsp: list attached clients",
    rhs = function()
      local res = {}
      for _, c in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
        table.insert(res, tostring(c.id) .. ":" .. c.config.name)
      end
      print(table.concat(res, ", "))
    end,
  },
  {
    mode = "n",
    lhs = "lsp: restart attached clients",
    rhs = function()
      vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
      vim.cmd("edit!")
    end,
  },
  {
    mode = "n",
    lhs = "lsp: list workspace folders",
    rhs = "<Cmd>lua = vim.lsp.buf.list_workspace_folders()<CR>",
  },

  --[[ highlight ]]
  {
    mode = "n",
    lhs = "toggle transparent background",
    rhs = function()
      require("atusy.highlight").change_background()
    end,
  },
}
