--[[
NOTE:
For some reason, ddc-ui-pum does not trigger User events...
So I prefer ddc-ui-native and use ddc-ui-pum only on cmdline.
--]]
local fn = vim.fn
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local DEBUG = false

local function commandline_post_buf()
  if vim.b.prev_buffer_config ~= nil then
    fn["ddc#custom#set_buffer"](vim.b.prev_buffer_config)
    vim.b.prev_buffer_config = nil
  else
    fn["ddc#custom#set_buffer"](vim.empty_dict())
  end
end

local function commandline_post(bufnr, maps)
  -- reset buffer
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_call(bufnr, commandline_post_buf)
  end

  -- reset global
  for lhs, _ in pairs(maps) do
    pcall(vim.keymap.del, "c", lhs)
  end
end

---@return string?, boolean
local function pumstate()
  local ui = vim.fn["ddc#custom#get_current"]().ui
  if ui == "pum" then
    return ui, vim.fn["pum#visible"]()
  end
  if ui == "native" then
    return ui, vim.fn.pumvisible() ~= 0
  end
  return nil, false
end

local maps = {
  ["<Tab>"] = function()
    local ui, visible = pumstate()
    if visible then
      if ui == "pum" then
        vim.fn["pum#map#insert_relative"](1)
        return
      end
      return "<C-N>"
    end
    local col = fn.col(".")
    if
      vim.api.nvim_get_mode().mode == "c"
      or (col > 1 and string.match(fn.strpart(fn.getline("."), col - 2), "%s") == nil)
    then
      -- requires feedkeys because mappings are replaced by internal representations
      vim.api.nvim_feedkeys(fn["ddc#map#manual_complete"](), "n", false)
      return
    end
    return "<Tab>"
  end,
  ["<S-Tab>"] = function()
    local ui, visible = pumstate()
    if visible then
      if ui == "pum" then
        fn["pum#map#insert_relative"](-1)
        return
      end
      return "<C-P>"
    end
    return "<S-Tab>"
  end,
  ["<C-Y>"] = function()
    local ui, visible = pumstate()
    if visible and ui == "pum" then
      fn["pum#map#confirm"]()
      return
    end
    return "<C-Y>"
  end,
  ["<C-X><C-Z>"] = function()
    local ui, visible = pumstate()
    if visible and ui == "pum" then
      fn["pum#map#cancel"]()
    end
    return "<C-X><C-Z>"
  end,
}

local function commandline_pre(bufnr, sources)
  -- register autocmd first so that they are registered regradless of
  -- the later errors
  local function cb()
    local ok, mes = pcall(commandline_post, bufnr, maps)
    if DEBUG and not ok and mes then
      vim.notify(mes)
    end
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "DDCCmdlineLeave",
    once = true,
    callback = cb,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    buffer = 0,
    callback = cb,
  })

  -- do initialization after registering autocmd
  for lhs, rhs in pairs(maps) do
    set_keymap("c", lhs, rhs, { silent = true, expr = false }) -- pum.vim does not allow expr mappings
  end
  if vim.b.prev_buffer_config == nil then
    -- Overwrite sources
    vim.b.prev_buffer_config = fn["ddc#custom#get_buffer"]()
  end
  fn["ddc#custom#patch_buffer"]("cmdlineSources", sources or { "cmdline", "cmdline-history", "file", "around" })

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function setup()
  -- insert
  local patch_global = fn["ddc#custom#patch_global"]
  patch_global("ui", "pum")
  patch_global("sources", { "nvim-lsp", "around", "file", "buffer" })
  patch_global("sourceOptions", {
    around = { mark = "A" },
    buffer = { mark = "B" },
    ["nvim-lsp"] = { mark = "L" },
    file = {
      mark = "F",
      isVolatile = true,
      forceCompletionPattern = [[\S/\S*]],
    },
    cmdline = { mark = "CMD" },
    ["cmdline-history"] = { mark = "CMD" },
    ["_"] = {
      matchers = { "matcher_fuzzy" },
      sorters = { "sorter_fuzzy" },
      converters = { "converter_fuzzy" },
    },
  })
  patch_global("sourceParams", {
    around = { maxSize = 500 },
  })
  patch_global(
    "autoCompleteEvents",
    { "InsertEnter", "TextChangedI", "TextChangedP", "CmdlineEnter", "CmdlineChanged" }
  )
  fn["ddc#custom#patch_buffer"]("sourceOptions", {
    file = {
      mark = "F",
      isVolatile = true,
      forceCompletionPattern = [[(^e\s+|\S/\S*)]],
    },
  })
  for lhs, rhs in pairs(maps) do
    set_keymap("i", lhs, rhs, { silent = true, expr = true })
  end

  -- cmdline
  set_keymap("n", "/", function()
    local ok, mes = pcall(commandline_pre, vim.api.nvim_get_current_buf(), { "buffer" })
    if DEBUG and not ok and mes then
      vim.notify(mes)
    end
    return "/"
  end, { expr = true })
  set_keymap("n", ":", function()
    local ok, mes = pcall(commandline_pre, vim.api.nvim_get_current_buf())
    if DEBUG and not ok and mes then
      vim.notify(mes)
    end
    return ":"
  end, { expr = true })

  -- enable
  fn["popup_preview#enable"]()
  fn["ddc#enable"]()
end

return {
  {
    "Shougo/ddc.vim",
    -- dir = "/home/atusy/ghq/github.com/Shougo/ddc.vim",
    dependencies = {
      { "vim-denops/denops.vim" },
      { "Shougo/pum.vim" },
      { "Shougo/ddc-matcher_head" }, -- 入力中の単語を補完
      { "Shougo/ddc-source-around" },
      { "Shougo/ddc-source-line" },
      { "Shougo/ddc-source-cmdline" },
      { "Shougo/ddc-source-cmdline-history" },
      { "Shougo/ddc-source-nvim-lsp" }, -- 入力中の単語を補完
      { "Shougo/ddc-ui-native" },
      { "Shougo/ddc-ui-pum" },
      { "matsui54/ddc-buffer" },
      { "LumaKernel/ddc-source-file" }, -- Suggest file paths
      { "Shougo/ddc-converter_remove_overlap" }, -- remove duplicates
      { "Shougo/ddc-sorter_rank" }, -- Sort suggestions
      { "tani/ddc-fuzzy" },
      { "matsui54/denops-popup-preview.vim", dependencies = { "vim-denops/denops.vim" } },
    },
    config = setup,
  },
}
