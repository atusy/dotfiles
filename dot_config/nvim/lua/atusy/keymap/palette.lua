local M = {
  star = "☆",
}

function M.set_item(item)
  local space = " " -- U+00A0
  local mode = item.mode
  local lhs = M.star
    .. item.lhs:gsub(" ", space) -- replace with U+00A0 to avoid showing <Space>
    .. space
    .. space -- append two spaces to avoid potential waiting
  local rhs = item.rhs or lhs
  local opts = vim.tbl_deep_extend("keep", item.opts or {}, { desc = "" })
  vim.keymap.set(mode, lhs, rhs, opts)
end

--- update needs be ran on demand so that mapping takes no time on init
function M.update()
  local failed = {}
  for _, item in pairs(M.items) do
    local ok, res = pcall(M.set_item, item)
    if not ok then
      table.insert(failed, { res, item })
    end
  end
  M.items = {}
  return failed
end

function M.add_item(mode, lhs, rhs, opts)
  table.insert(M.items, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
end

M.items = {
  --[[ window ]]
  { mode = "n", lhs = "window: equalize horizontally", rhs = "<Cmd>hroizontal wincmd =<CR>" },
  { mode = "n", lhs = "window: equalize vertically", rhs = "<Cmd>vertical wincmd =<CR>" },
  --[[ clipboard ]]
  { mode = "n", lhs = "clipboard: cwd", rhs = "<Cmd>let @+=getcwd()<CR>" },
  { mode = "n", lhs = "clipboard: abs path of %", rhs = '<Cmd>let @+=expand("%:p")<CR>' },
  { mode = "n", lhs = "clipboard: abs path of dirname of %", rhs = '<Cmd>let @+=expand("%:p:h")<CR>' },
  --[[ treesitter ]]
  { mode = "n", lhs = "treesitter: inspect tree", rhs = vim.treesitter.inspect_tree },
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

return M
