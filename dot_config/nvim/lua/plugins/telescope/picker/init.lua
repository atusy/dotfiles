local utils = require("atusy.utils")

local M = {}

function M.outline()
  local picker = require("telescope.builtin").treesitter
  if vim.tbl_contains({ "markdown" }, vim.bo.filetype) then
    local ok, aerial = pcall(function()
      require("aerial") -- ensure lazy loading
      return require("telescope._extensions").manager.aerial.aerial
    end)
    picker = ok and aerial or picker
  end
  picker({ sorter = require("plugins.telescope.sorter").filter_only_sorter() })
end

local keymaps_default_text = {
  fern = "'fern-action ",
  ["gin-status"] = "'gin-action ",
  ["gin-log"] = "'gin-log ",
}

function M.keymaps(opts)
  require("atusy.lazy").load_all()
  require("atusy.keymap.palette").update()
  require("telescope.builtin").keymaps(opts or {
    modes = { vim.api.nvim_get_mode().mode },
    default_text = vim.b.telescope_keymaps_default_text or keymaps_default_text[vim.bo.filetype] or utils.star,
  })
end

function M.help_tags(opts)
  require("atusy.lazy").load_all()
  require("telescope.builtin").help_tags(opts or { lang = "ja" })
end

return M
