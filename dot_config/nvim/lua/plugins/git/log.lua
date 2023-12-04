local M = {}

function M.exec_graph(...)
  vim.cmd.GinLog({
    args = { "--graph", "--topo-order", "-C", "-M", "--pretty=format:%C(#999999)%h%Creset %Cgreen%d%Creset %s", ... },
  })
end

function M.show(...)
  vim.cmd.GinBuffer({
    args = vim.tbl_flatten({
      "++processor=delta --no-gitconfig --color-only",
      "show",
      ...,
    }),
  })
end

function M.show_below(...)
  local winc = vim.api.nvim_get_current_win()
  local winj = vim.fn.win_getid(vim.fn.winnr("j"))
  if winc == winj or not vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winj)):match("^gin://") then
    vim.cmd([[leftabove split]])
    winj = vim.fn.win_getid(vim.fn.winnr("j"))
  end
  local args = { ... }
  vim.api.nvim_win_call(winj, function()
    M.show(args)
  end)
end

function M.map(ctx)
  local yank = [["z<Plug>(gin-action-yank:commit)]]
  local show_below = yank
    .. [[<Cmd>lua require('plugins.git.log').show_below('--stat', '--patch', vim.fn.getreg('z'))<CR>]]
  vim.keymap.set("n", "<Down>", "<Down>" .. show_below, { buffer = ctx.buf })
  vim.keymap.set("n", "<Up>", "<Up>" .. show_below, { buffer = ctx.buf })
  vim.keymap.set("n", "<CR>", show_below, { buffer = ctx.buf })
  vim.keymap.set(
    "n",
    "<Plug>(gin-action-fixup)",
    yank .. [[<Cmd>lua vim.cmd.Gin({ args = { "commit", "--fixup", vim.fn.getreg("z") } })<CR>]],
    { buffer = ctx.buf }
  )
end

return M
