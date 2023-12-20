local function commandline_pre(mode)
  local buf = vim.api.nvim_get_current_buf()
  local opts = vim.fn["ddc#custom#get_buffer"]()
  vim.fn["pum#set_local_option"](mode, "min_height", vim.o.pumheight)
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("atusy.ddc.commandline_pre", {}),
    pattern = "DDCCmdlineLeave",
    once = true,
    desc = "revert temporary settings",
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_call(buf, function()
          vim.fn["ddc#custom#set_buffer"](opts or vim.empty_dict())
        end)
      end
    end,
  })
  local enabledIf = string.format(
    [[getcmdline() =~# "^\\(%s\\)" ? v:true : v:false]],
    table.concat({ "!", "Make ", "Gin ", "GinBuffer " }, [[\\|]])
  )
  vim.fn["ddc#custom#patch_buffer"]("sourceOptions", {
    file = { forceCompletionPattern = [[(^e\s+|\S/\S*)]] },
    fish = { enabledIf = enabledIf },
    xonsh = { enabledIf = enabledIf },
    zsh = { enabledIf = enabledIf },
    shell_history = { enabledIf = [[getcmdline()[0] == "!" ? v:true : v:false]] },
    -- ["_"] = mode == ":" and { keywordPattern = "[0-9a-zA-Z_:#-]*" },
  })

  -- Enable command line completion
  vim.fn["ddc#enable_cmdline_completion"]()
end

local function config()
  -- general
  vim.keymap.set({ "i", "c" }, "<Tab>", function()
    if vim.fn["pum#visible"]() then
      return "<Cmd>call pum#map#insert_relative(+1)<CR>"
    end
    if vim.api.nvim_get_mode().mode == "c" then
      return "<Cmd>call ddc#map#manual_complete()<CR>"
    end
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".") ---@diagnostic disable-line: param-type-mismatch
    if col > 1 and type(line) == "string" and string.match(vim.fn.strpart(line, col - 2), "%s") == nil then
      return "<Cmd>call ddc#map#manual_complete()<CR>"
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
  vim.keymap.set({ "i", "c" }, "<c-x><cr>", function()
    vim.notify(vim.inspect(vim.fn["pum#current_item"]()))
  end)

  -- on insert
  vim.keymap.set("i", "<c-x><c-f>", function()
    vim.fn["ddc#map#manual_complete"]({ sources = { "file" } })
  end)

  -- on cmdline
  for _, lhs in pairs({ ":", "/", "?" }) do
    vim.keymap.set({ "n", "x" }, lhs, function()
      pcall(commandline_pre, lhs)
      return lhs
    end, { expr = true })
  end
  vim.keymap.set("c", "<c-x><c-space>", function()
    local t = vim.fn.getcmdtype()
    local line = vim.fn.getcmdline()
    local match = function(x)
      return x == line
    end
    if vim.fn["pum#current_item"]().menu == "RECENT" then
      match = function(x)
        return x == line or vim.startswith(x, line .. " ") or vim.startswith(x, line .. "! ")
      end
    end
    for i = -1, -vim.fn.histnr(t), -1 do
      if match(vim.fn.histget(t, i)) then
        vim.fn.histdel(t, i)
        vim.cmd("wshada!")
        return
      end
    end
  end)

  -- enable
  vim.fn["ddc#custom#load_config"](vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "ddc.ts"))
  vim.fn["popup_preview#enable"]()
  vim.fn["ddc#enable"]()
  require("plugins.ddc.gitcommit")()
end

return {
  {
    "https://github.com/Shougo/ddc.vim",
    dependencies = {
      { "https://github.com/vim-denops/denops.vim" },
      -- ui
      { "https://github.com/matsui54/denops-popup-preview.vim" },
      { "https://github.com/Shougo/pum.vim" },
      -- source
      { "https://github.com/atusy/ddc-source-parametric" },
      { "https://github.com/matsui54/ddc-buffer" },
      { "https://github.com/matsui54/ddc-dictionary" },
      { "https://github.com/Shougo/ddc-source-around" },
      { "https://github.com/Shougo/ddc-source-cmdline" },
      { "https://github.com/Shougo/ddc-source-cmdline-history" },
      { "https://github.com/Shougo/ddc-source-input" },
      { "https://github.com/Shougo/ddc-source-line" },
      { "https://github.com/Shougo/ddc-source-lsp" },
      { "https://github.com/Shougo/ddc-source-shell-native" },
      { "https://github.com/Shougo/ddc-ui-pum" },
      { "https://github.com/LumaKernel/ddc-source-file" },
      -- filter
      { "https://github.com/tani/ddc-fuzzy" },
      -- sorter
      { "https://github.com/Shougo/ddc-filter-sorter_rank" },
      -- matcher
      { "https://github.com/Shougo/ddc-filter-matcher_head" },
      { "https://github.com/Shougo/ddc-filter-matcher_vimregexp" },
      { "https://github.com/matsui54/ddc-filter_editdistance" },
      -- converter
      { "https://github.com/Shougo/ddc-filter-converter_remove_overlap" },
      { "https://github.com/Shougo/ddc-filter-converter_truncate_abbr" },
      { "https://github.com/atusy/ddc-filter-converter_string_match" },
      { "https://github.com/atusy/ddc-filter-converter_dictionary" },
    },
    config = config,
    build = function(p)
      local dir = require("atusy.lazy").dir(p)
      local obj = vim.system({
        "git",
        "update-index",
        "--skip-worktree",
        vim.print(vim.fs.joinpath(dir, "denops/ddc/_mods.js")),
      }, { cwd = dir })
      obj:wait()
      vim.fn["ddc#set_static_import_path"]()
    end,
  },
  -- dictionaries for ddc (install only)
  { "https://github.com/dwyl/english-words", lazy = true },
  { "https://github.com/gunyarakun/kantan-ej-dictionary", lazy = true },
  { "https://github.com/matthewreagan/WebstersEnglishDictionary", lazy = true },
  -- for debugging (install only)
  { "https://github.com/Shougo/ddc-ui-native", lazy = true },
}
