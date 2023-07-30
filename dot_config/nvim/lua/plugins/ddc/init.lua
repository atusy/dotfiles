local fn = vim.fn
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local function commandline_pre(buf, mode)
  local opts = vim.fn["ddc#custom#get_buffer"]()
  vim.api.nvim_create_autocmd("User", {
    group = utils.augroup,
    pattern = "DDCCmdlineLeave",
    once = true,
    desc = "revert temporary settings",
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_call(buf, function()
          vim.fn["pum#set_option"]({ reversed = false })
          fn["ddc#custom#set_buffer"](opts or vim.empty_dict())
        end)
      end
    end,
  })
  vim.fn["pum#set_option"]({ reversed = true })
  fn["ddc#custom#patch_buffer"]("sourceOptions", {
    file = { forceCompletionPattern = [[(^e\s+|\S/\S*)]] },
    fish = { enabledIf = [[getcmdline()[0] == "!" ? v:true : v:false]] },
    xonsh = { enabledIf = [[getcmdline()[0] == "!" ? v:true : v:false]] },
    zsh = { enabledIf = [[getcmdline() =~# "^\\(!\\|Gin\\(Buffer\\)\\? \\)" ? v:true : v:false]] },
    -- ["_"] = mode == ":" and { keywordPattern = "[0-9a-zA-Z_:#-]*" },
  })

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function config()
  -- general
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
    if vim.api.nvim_get_mode().mode == "c" then
      return "<c-u><c-c>"
    end
    return "<c-c>"
  end, { expr = true })

  -- on entering cmdline
  for _, lhs in pairs({ "/", ":" }) do
    set_keymap({ "n", "x" }, lhs, function()
      pcall(commandline_pre, vim.api.nvim_get_current_buf(), lhs)
      return lhs
    end, { expr = true })
  end

  -- enable
  fn["ddc#custom#load_config"](vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "ddc.ts"))
  fn["popup_preview#enable"]()
  fn["ddc#enable"]()
  require("plugins.ddc.git-prefix")()
end

return {
  {
    "Shougo/ddc.vim",
    -- dir = "/home/atusy/ghq/github.com/Shougo/ddc.vim",
    dependencies = {
      { "vim-denops/denops.vim" },
      -- ui
      { "matsui54/denops-popup-preview.vim" },
      { "Shougo/pum.vim" },
      { "Shougo/ddc-ui-native", lazy = true }, -- install only
      -- source
      { "atusy/ddc-source-parametric" },
      { "matsui54/ddc-dictionary" },
      { "Shougo/ddc-source-around" },
      { "Shougo/ddc-source-cmdline" },
      { "Shougo/ddc-source-cmdline-history" },
      { "Shougo/ddc-source-input" },
      { "Shougo/ddc-source-line" },
      { "Shougo/ddc-source-nvim-lsp" },
      { "Shougo/ddc-source-shell-native" },
      { "Shougo/ddc-ui-pum" },
      { "matsui54/ddc-buffer" },
      { "LumaKernel/ddc-source-file" },
      { "Shougo/ddc-sorter_rank" },
      -- filter
      { "tani/ddc-fuzzy" },
      -- matcher
      { "Shougo/ddc-matcher_head" },
      { "Shougo/ddc-filter-matcher_vimregexp" },
      { "matsui54/ddc-filter_editdistance" },
      -- converter
      { "Shougo/ddc-converter_remove_overlap" },
      { "Shougo/ddc-converter_truncate_abbr" },
      { "atusy/ddc-filter-converter_string_match" },
      -- dict
      { "dwyl/english-words", lazy = true }, -- install only
    },
    config = config,
  },
}
