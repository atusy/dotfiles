local vim = vim
local fn = vim.fn
local utils = require('utils')
local set_keymap = utils.set_keymap

local function commandline_post(maps)
  for lhs, _ in pairs(maps) do
    pcall(vim.keymap.del, 'c', lhs)
  end
  if vim.b.prev_buffer_config ~= nil then
    fn["ddc#custom#set_buffer"](vim.b.prev_buffer_config)
    vim.b.prev_buffer_config = nil
  else
    fn["ddc#custom#set_buffer"]({})
  end
end

local pum_visible = fn["pum#visible"]

local maps = {
  ['<Tab>'] = function()
    if pum_visible() then
      return '<Cmd>call pum#map#insert_relative(+1)<CR>'
    end
    local col = fn.col('.')
    if vim.api.nvim_get_mode().mode == 'c' or
        (col > 1 and string.match(fn.strpart(fn.getline('.'), col - 2), '%s') == nil)
    then
      local code = fn['ddc#map#manual_complete']() -- termcodes are replaced
      vim.api.nvim_feedkeys(code, 'n', false)
      return
    end
    return '<Tab>'
  end,
  ['<S-Tab>'] = function() fn["pum#map#insert_relative"](-1) end,
  ['<C-Y>'] = function()
    if pum_visible() then
      fn["pum#map#confirm"]()
    else
      return '<C-Y>'
    end
  end,
  ['<C-E>'] = function()
    if pum_visible() then
      fn["pum#map#cancel"]()
    else
      return '<C-E>'
    end
  end,
}

local function commandline_pre()
  -- register autocmd first so that they are registered regradless of
  -- the later errors
  local augroup = vim.api.nvim_create_augroup("ddc-commandline-post", {})
  vim.api.nvim_create_autocmd("User", {
    pattern = "DDCCmdLineLeave",
    group = augroup,
    once = true,
    callback = function() pcall(commandline_post, maps) end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup,
    once = true,
    buffer = 0,
    callback = function() pcall(commandline_post, maps) end,
  })

  -- do initialization after registering autocmd
  for lhs, rhs in pairs(maps) do
    set_keymap('c', lhs, rhs, { silent = true, expr = true })
  end
  if vim.b.prev_buffer_config == nil then
    -- Overwrite sources
    vim.b.prev_buffer_config = fn["ddc#custom#get_buffer"]()
  end
  fn["ddc#custom#patch_buffer"]('cmdlineSources', { 'cmdline', 'cmdline-history', 'file', 'around' })

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function setup()
  -- insert
  local patch_global = fn["ddc#custom#patch_global"]
  patch_global('ui', 'pum')
  patch_global('sources', { 'nvim-lsp', 'around', 'file' })
  patch_global('sourceOptions', {
    around = { mark = 'A', maxSize = 500 },
    ['nvim-lsp'] = { mark = 'L' },
    file = {
      mark = 'F',
      isVolatile = true,
      forceCompletionPattern = [[\S/\S*]],
    },
    cmdline = { mark = 'CMD' },
    ['cmdline-history'] = { mark = 'CMD' },
    ['_'] = {
      matchers = { 'matcher_fuzzy' },
      sorters = { 'sorter_fuzzy' },
      converters = { 'converter_fuzzy' },
    },
  })
  patch_global(
    'autoCompleteEvents',
    { 'InsertEnter', 'TextChangedI', 'TextChangedP', 'CmdlineEnter', 'CmdlineChanged' }
  )
  fn["ddc#custom#patch_buffer"]('sourceOptions', {
    file = {
      mark = 'F',
      isVolatile = true,
      forceCompletionPattern = [[(^e\s+|\S/\S*)]],
    },
  })
  for lhs, rhs in pairs(maps) do
    set_keymap('i', lhs, rhs, { silent = true, expr = true })
  end

  -- cmdline
  set_keymap('n', ':', function() pcall(commandline_pre) return ':' end, { expr = true })

  fn["popup_preview#enable"]()
  fn["ddc#enable"]()
end

return {
  deps = {
    { 'Shougo/ddc.vim' },
    { 'Shougo/ddc-around' },
    { 'Shougo/ddc-cmdline' },
    { 'Shougo/ddc-cmdline-history' },
    { 'Shougo/ddc-matcher_head' }, -- 入力中の単語を補完
    { 'Shougo/ddc-nvim-lsp' }, -- 入力中の単語を補完
    -- { 'Shougo/ddc-ui-native' },
    { 'Shougo/ddc-ui-pum' },
    { 'LumaKernel/ddc-file' }, -- Suggest file paths
    { 'Shougo/ddc-converter_remove_overlap' }, -- remove duplicates
    { 'Shougo/ddc-sorter_rank' }, -- Sort suggestions
    { 'Shougo/pum.vim' }, -- Show popup window
    { 'tani/ddc-fuzzy' },
    { 'matsui54/denops-popup-preview.vim' },
  },
  setup = setup,
}
