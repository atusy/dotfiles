--[[
NOTE:
For some reason, ddc-ui-pum does not trigger User events...
So I prefer ddc-ui-native and use ddc-ui-pum only on cmdline.
--]]
local fn = vim.fn
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local DEBUG = false

local function commandline_post_buf(buf, opts)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_call(buf, function()
      vim.fn["pum#set_option"]({ reversed = false })
      fn["ddc#custom#set_buffer"](opts or vim.empty_dict())
    end)
  end
end

local function commandline_pre(bufnr, mode)
  local opts = vim.fn["ddc#custom#get_buffer"]()
  vim.api.nvim_create_autocmd("User", {
    group = utils.augroup,
    pattern = "DDCCmdlineLeave",
    once = true,
    callback = function()
      commandline_post_buf(bufnr, opts)
    end,
  })
  vim.fn["pum#set_option"]({ reversed = true })
  fn["ddc#custom#patch_buffer"]("sourceOptions", {
    file = { forceCompletionPattern = [[(^e\s+|\S/\S*)]] },
    zsh = { enabledIf = [[getcmdline() =~# "^\\(!\\|Gin\\(Buffer\\)\\? \\)" ? v:true : v:false]] },
    -- ["_"] = mode == ":" and { keywordPattern = "[0-9a-zA-Z_:#-]*" },
  })

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function setup()
  -- insert
  local patch_global = fn["ddc#custom#patch_global"]
  patch_global({
    ui = "pum",
    autoCompleteEvents = { "InsertEnter", "TextChangedI", "TextChangedP", "CmdlineEnter", "CmdlineChanged" },
    sources = { "nvim-lsp", "around", "file", "buffer", "skkeleton" },
    cmdlineSources = {
      [":"] = { "cmdline-history", "cmdline", "zsh", "file", "around" },
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
    ["nvim-lsp"] = { mark = "L", forceCompletionPattern = [[\S]] },
    file = {
      mark = "F",
      isVolatile = true,
      forceCompletionPattern = [[\S/\S*]],
    },
    input = { mark = "I", isVolatile = true, minAutoCompleteLength = 1 },
    ["cmdline"] = { mark = "C", minAutoCompleteLength = 1 },
    ["cmdline-history"] = {
      mark = "H",
      maxItems = 1,
      minAutoCompleteLength = 0,
      minKeywordLength = 2,
      sorters = {}, -- no sorters to prioritize latest history
    },
    zsh = {
      mark = "Z",
      minAutoCompleteLength = 0,
      minKeywordLength = 2,
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
    ["nvim-lsp"] = {
      enableResolveItem = true,
      enableAdditionalTextEdit = true,
    },
    zsh = { envs = { FPATH = vim.fn.system([[zsh -i -c 'echo -n "$FPATH"']]) } },
  })
  fn["ddc#custom#patch_filetype"]({ "bash", "zsh", "sh" }, {
    sources = { "nvim-lsp", "zsh", "around", "file", "buffer", "skkeleton" },
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
  vim.keymap.set("i", "<c-c>", function()
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
    local ok, mes = pcall(commandline_pre, vim.api.nvim_get_current_buf(), ":")
    if DEBUG and not ok and mes then
      vim.notify(mes)
    end
    return ":"
  end, { expr = true })
  vim.keymap.set("c", "<c-c>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#cancel()<CR>"
    end
    return "<c-u><bs>" -- Leave without histadd
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
      { "Shougo/ddc-matcher_head" },
      { "Shougo/ddc-source-around" },
      { "Shougo/ddc-source-cmdline" },
      { "Shougo/ddc-source-cmdline-history" },
      { "Shougo/ddc-source-input" },
      { "Shougo/ddc-source-line" },
      { "Shougo/ddc-source-nvim-lsp" },
      { "Shougo/ddc-ui-pum" },
      { "matsui54/ddc-buffer" },
      { "LumaKernel/ddc-source-file" },
      { "Shougo/ddc-sorter_rank" },
      { "tani/ddc-fuzzy" },
      { "matsui54/denops-popup-preview.vim" },
      -- { "Shougo/ddc-converter_remove_overlap" },
    },
    config = setup,
  },
}
