local utils = require("atusy.utils")

local M = {}

function M.outline()
  local picker
  if vim.tbl_contains({ "markdown" }, vim.bo.filetype) then
    local ok, aerial = pcall(function()
      require("aerial") -- ensure lazy loading
      return require("telescope._extensions").manager.aerial.aerial
    end)
    picker = ok and aerial
  end
  (picker or require("telescope.builtin").treesitter)({
    sorter = require("plugins.telescope.sorter").filter_only_sorter(),
  })
end

local keymaps_default_text = {
  fern = "'fern-action ",
  ["gin-status"] = "'gin-action ",
}

function M.keymaps()
  local ft = vim.bo.filetype
  require("telescope.builtin").keymaps({
    modes = { vim.api.nvim_get_mode().mode },
    default_text = vim.b.telescope_keymaps_default_text or keymaps_default_text[ft] or utils.star,
  })
end

return M
