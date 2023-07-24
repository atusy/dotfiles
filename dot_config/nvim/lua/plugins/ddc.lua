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
  vim.fn["pum#set_option"]({
    reversed = false,
  })

  if vim.b.prev_buffer_config ~= nil then
    fn["ddc#custom#set_buffer"](vim.b.prev_buffer_config)
    vim.b.prev_buffer_config = nil
  else
    fn["ddc#custom#set_buffer"](vim.empty_dict())
  end
end

local function commandline_pre(bufnr)
  vim.api.nvim_create_autocmd("User", {
    group = utils.augroup,
    pattern = "DDCCmdlineLeave",
    once = true,
    callback = function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_call(bufnr, commandline_post_buf)
      end
    end,
  })
  vim.fn["pum#set_option"]({
    reversed = true,
  })

  -- do initialization after registering autocmd
  vim.b.prev_buffer_config = fn["ddc#custom#get_buffer"]()

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function setup()
  -- insert
  local patch_global = fn["ddc#custom#patch_global"]
  patch_global({
    ui = "pum",
    sources = { "nvim-lsp", "around", "file", "buffer" },
    autoCompleteEvents = {
      "InsertEnter",
      "TextChangedI",
      "TextChangedP",
      "CmdlineEnter",
      "CmdlineChanged",
    },
    cmdlineSources = {
      [":"] = { "cmdline-history", "cmdline", "around" },
      ["@"] = { "cmdline-history", "input", "file", "around" },
      [">"] = { "cmdline-history", "input", "file", "around" },
      ["/"] = { "around", "line" },
      ["?"] = { "around", "line" },
      ["-"] = { "around", "line" },
      ["="] = { "input" },
    },
  })
  patch_global("sourceOptions", {
    around = { mark = "A" },
    buffer = { mark = "B" },
    ["nvim-lsp"] = { mark = "L" },
    file = {
      mark = "F",
      isVolatile = true,
      forceCompletionPattern = [[\S/\S*]],
    },
    ["cmdline"] = { mark = "C", minAutoCompleteLength = 1 },
    ["cmdline-history"] = {
      mark = "H",
      maxItems = 1,
      minAutoCompleteLength = 0,
      minKeywordLength = 2,
      sorters = {}, -- no sorters to prioritize latest history
    },
    ["_"] = {
      ignoreCase = true,
      matchers = { "matcher_fuzzy" },
      sorters = { "sorter_fuzzy" },
      converters = { "converter_fuzzy" },
    },
  })
  patch_global("sourceParams", {
    around = { maxSize = 500 },
  })
  fn["ddc#custom#patch_buffer"]("sourceOptions", {
    file = {
      mark = "F",
      isVolatile = true,
      forceCompletionPattern = [[(^e\s+|\S/\S*)]],
    },
  })

  vim.keymap.set({ "i", "c" }, "<Tab>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#insert_relative(+1)<CR>"
    end
    if vim.api.nvim_get_mode().mode == "c" then
      return vim.fn["ddc#map#manual_complete"]()
    end
    local col = fn.col(".")
    if col > 1 and string.match(fn.strpart(fn.getline("."), col - 2), "%s") == nil then
      return fn["ddc#map#manual_complete"]()
    end
    return "<Tab>"
  end, { expr = true })
  vim.keymap.set({ "i", "c" }, "<s-tab>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#insert_relative(-1)<CR>"
    end
    return "<S-Tab>"
  end, { expr = true })
  vim.keymap.set({ "i", "c" }, "<c-y>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#confirm()<CR>"
    end
    return "<C-Y>"
  end, { expr = true })
  vim.keymap.set({ "i", "c" }, "<c-c>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#cancel()<CR>"
    end
    return "<c-c>"
  end, { expr = true })

  -- cmdline
  set_keymap("n", "/", function()
    local ok, mes = pcall(commandline_pre, vim.api.nvim_get_current_buf())
    if DEBUG and not ok and mes then
      vim.notify(mes)
    end
    return "/"
  end, { expr = true })
  set_keymap({ "n", "x" }, ":", function()
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
