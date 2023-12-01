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

function M.locations(opts, locations, title)
  local conf = require("telescope.config").values
  require("telescope.pickers")
    .new(opts, {
      prompt_titile = title or "Locations",
      finder = require("telescope.finders").new_table({
        results = locations,
        entry_maker = require("telescope.make_entry").gen_from_quickfix(opts),
      }),
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
      push_cursor_on_edit = true,
      push_tagstack_on_edit = true,
    })
    :find()
end

function M.gtd(opts, bufnr, method, params)
  opts = opts or {}
  method = method or "textDocument/definition"
  vim.lsp.buf_request_all(bufnr or 0, method, params or vim.lsp.util.make_position_params(0, "utf-8"), function(resps)
    local locs = {}
    for _, resp in pairs(resps) do
      for _, i in pairs(resp.result or {}) do
        table.insert(locs, i)
      end
    end

    if #locs == 0 then
      pcall(vim.cmd.normal, { args = { "gF" }, bang = true })
    elseif #locs == 1 then
      vim.lsp.util.jump_to_location(locs[1], "utf-8", false)
    else
      M.locations(opts, vim.lsp.util.locations_to_items(locs, "utf-8"), "LSP definitions")
    end
  end)
end

return M
