local M = {
  star = "☆",
}

--- update needs be ran on demand so that mapping takes no time on init
function M.update()
  local failed = {}
  local space = " " -- U+00A0
  for _, item in pairs(M.items) do
    local mode = item.mode
    local lhs = M.star
      .. item.lhs:gsub(" ", space) -- replace with U+00A0 to avoid showing <Space>
      .. space
      .. space -- append two spaces to avoid potential waiting
    local rhs = item.rhs or lhs
    local opts = vim.tbl_deep_extend("keep", item.opts or {}, { desc = "" })
    local ok, res = pcall(vim.keymap.set, mode, lhs, rhs, opts)
    if not ok then
      table.insert(failed, { item.lhs, res })
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
  { "n", "window: equalize horizontally", "<Cmd>hroizontal wincmd =<CR>" },
  { "n", "window: equalize vertically", "<Cmd>vertical wincmd =<CR>" },
  --[[ clipboard ]]
  { "n", "clipboard: cwd", "<Cmd>let @+=getcwd()<CR>" },
  { "n", "clipboard: abs path of %", '<Cmd>let @+=expand("%:p")<CR>' },
  { "n", "clipboard: abs path of dirname of %", '<Cmd>let @+=expand("%:p:h")<CR>' },
  --[[ treesitter ]]
  { "n", "treesitter: inspect tree", vim.treesitter.inspect_tree },
  {
    "n",
    "redraw!",
    [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
    { desc = "with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter" },
  },

  --[[ lsp ]]
  {
    "n",
    "lsp: list attached clients",
    function()
      local res = {}
      for _, c in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
        table.insert(res, tostring(c.id) .. ":" .. c.config.name)
      end
      print(table.concat(res, ", "))
    end,
  },
  {
    "n",
    "lsp: restart attached clients",
    function()
      vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
      vim.cmd("edit!")
    end,
  },
}

return M
