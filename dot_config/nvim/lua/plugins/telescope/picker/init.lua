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

function M.gtd(opts)
  opts = opts or {}
  local method = "textDocument/definition"
  local handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(_, result, ctx, config)
    vim.lsp.handlers[method] = handler
    if result == nil or vim.tbl_isempty(result) then
      local ok = pcall(vim.cmd.normal, { args = { "gF" }, bang = true })
      if ok then
        return
      end
    end
    handler(_, result, ctx, config)
  end
  vim.lsp.buf.definition({
    on_list = function(data)
      if #data.items > 1 then
        M.locations(opts, data.items, data.title)
        return
      end
      local item = data.items[1]
      local bufnr = vim.uri_to_bufnr(item.user_data.targetUri)
      if vim.api.nvim_win_get_buf(0) ~= bufnr then
        vim.api.nvim_win_set_buf(0, bufnr)
      end
      vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
    end,
  })
end

return M
