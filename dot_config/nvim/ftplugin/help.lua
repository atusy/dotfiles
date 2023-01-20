pcall(vim.treesitter.start)
vim.wo.conceallevel = 0

local wins = vim.api.nvim_tabpage_list_wins(0)
local wins_help = vim.tbl_filter(
  function(w)
    local ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(w), 'filetype')
    return ft == 'help'
  end,
  wins
)
if #wins_help == 1 then
  vim.api.nvim_win_call(wins_help[1], function() vim.cmd('wincmd L') end)
end
