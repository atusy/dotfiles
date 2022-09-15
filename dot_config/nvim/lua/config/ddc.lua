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

local function commandline_pre(maps)
  maps = maps or {
    ['<Tab>'] = function() fn["pum#map#insert_relative"](1) end,
    ['<S-Tab>'] = function() fn["pum#map#insert_relative"](-1) end,
    ['<C-Y>'] = function() fn["pum#map#confirm"]() end,
    ['<C-E>'] = function() fn["pum#map#cancel"]() end,
  }
  for lhs, rhs in pairs(maps) do
    set_keymap('c', lhs, rhs)
  end
  if vim.b.prev_buffer_config == nil then
    -- Overwrite sources
    vim.b.prev_buffer_config = fn["ddc#custom#get_buffer"]()
  end
  fn["ddc#custom#patch_buffer"]('cmdlineSources', { 'cmdline', 'cmdline-history', 'file', 'around' })
  vim.api.nvim_create_autocmd("User", {
    pattern = "DDCCmdLineLeave",
    once = true,
    callback = function() pcall(commandline_post, maps) end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    buffer = 0,
    callback = function() pcall(commandline_post, maps) end,
  })

  -- Enable command line completion
  fn["ddc#enable_cmdline_completion"]()
end

local function setup()
  local patch_global = fn["ddc#custom#patch_global"]
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
  patch_global('completionMenu', 'pum.vim')
  --[[
  inoremap <silent><expr> <TAB>
        \ pum#visible() ? '<Cmd>call pum#map#insert_relative(+1)<CR>' :
        \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
        \ '<TAB>' : ddc#manual_complete()
  --]]
  set_keymap(
    'i', '<TAB>',
    function()
      if fn["pum#visible"]() then
        return '<Cmd>call pum#map#insert_relative(+1)<CR>'
      end
      local col = fn.col('.')
      if (col > 1 and string.match(fn.getline('.')[col - 2], '%s') == nil) then
        return fn["ddc#manual_complete"]()
      end
      return '<TAB>'
    end,
    { silent = true, expr = true }
  )
  set_keymap('i', '<S-Tab>', function() fn["pum#map#insert_relative"](-1) end)
  set_keymap('i', '<C-y> ', function() fn["pum#map#confirm"]() end)
  set_keymap('i', '<C-e>', function() fn["pum#map#cancel"]() end)
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
  patch_global(
    'autoCompleteEvents',
    { 'InsertEnter', 'TextChangedI', 'TextChangedP', 'CmdlineChanged' }
  )
  set_keymap('n', ':', function()
    commandline_pre()
    return ':'
  end, { expr = true })

  fn["popup_preview#enable"]()
  fn["ddc#enable"]()
end

return {
  deps = {},
  setup = setup,
}
