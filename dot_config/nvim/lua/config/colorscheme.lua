-- const
local api = vim.api
local fn = vim.fn
local DEFAULT_COLORSCHEME = 'catppuccin'
local OUTSIDE_COLORSCHEME = 'terafox'
local TAB_COLORSCHEME = 'carbonfox'
local ILLUMINATION = { bg = "#383D47" }

-- set colorscheme
local function hl_treesitter()
  local hl = function(group, opts)
    local exists = pcall(api.nvim_get_hl_by_name, group, false)
    if not exists then return end
    opts.default = true
    api.nvim_set_hl(0, group, opts)
  end

  -- Misc {{{
  hl('@comment', { link = 'Comment' })
  -- hl('@error', {link = 'Error'})
  hl('@none', { bg = 'NONE', fg = 'NONE' })
  hl('@preproc', { link = 'PreProc' })
  hl('@define', { link = 'Define' })
  hl('@operator', { link = 'Operator' })
  -- }}}

  -- Punctuation {{{
  hl('@punctuation.delimiter', { link = 'Delimiter' })
  hl('@punctuation.bracket', { link = 'Delimiter' })
  hl('@punctuation.special', { link = 'Delimiter' })
  -- }}}

  -- Literals {{{
  hl('@string', { link = 'String' })
  hl('@string.regex', { link = 'String' })
  hl('@string.escape', { link = 'SpecialChar' })
  hl('@string.special', { link = 'SpecialChar' })

  hl('@character', { link = 'Character' })
  hl('@character.special', { link = 'SpecialChar' })

  hl('@boolean', { link = 'Boolean' })
  hl('@number', { link = 'Number' })
  hl('@float', { link = 'Float' })
  -- }}}

  -- Functions {{{
  hl('@function', { link = 'Function' })
  hl('@function.call', { link = 'Function' })
  hl('@function.builtin', { link = 'Special' })
  hl('@function.macro', { link = 'Macro' })

  hl('@method', { link = 'Function' })
  hl('@method.call', { link = 'Function' })

  hl('@constructor', { link = 'Special' })
  hl('@parameter', { link = 'Identifier' })
  -- }}}

  -- Keywords {{{
  hl('@keyword', { link = 'Keyword' })
  hl('@keyword.function', { link = 'Keyword' })
  hl('@keyword.operator', { link = 'Keyword' })
  hl('@keyword.return', { link = 'Keyword' })

  hl('@conditional', { link = 'Conditional' })
  hl('@repeat', { link = 'Repeat' })
  hl('@debug', { link = 'Debug' })
  hl('@label', { link = 'Label' })
  hl('@include', { link = 'Include' })
  hl('@exception', { link = 'Exception' })
  -- }}}

  -- Types {{{
  hl('@type', { link = 'Type' })
  hl('@type.builtin', { link = 'Type' })
  hl('@type.qualifier', { link = 'Type' })
  hl('@type.definition', { link = 'Typedef' })

  hl('@storageclass', { link = 'StorageClass' })
  hl('@attribute', { link = 'PreProc' })
  hl('@field', { link = 'Identifier' })
  hl('@property', { link = 'Function' })
  -- }}}

  -- Identifiers {{{
  hl('@variable', { link = 'Normal' })
  hl('@variable.builtin', { link = 'Special' })

  hl('@constant', { link = 'Constant' })
  hl('@constant.builtin', { link = 'Special' })
  hl('@constant.macro', { link = 'Define' })

  hl('@namespace', { link = 'Include' })
  hl('@symbol', { link = 'Identifier' })
  -- }}}

  -- Text {{{
  hl('@text', { link = 'Normal' })
  hl('@text.strong', { bold = true })
  hl('@text.emphasis', { italic = true })
  hl('@text.underline', { underline = true })
  hl('@text.strike', { strikethrough = true })
  hl('@text.title', { link = 'Title' })
  hl('@text.literal', { link = 'String' })
  hl('@text.uri', { link = 'Underlined' })
  hl('@text.math', { link = 'Special' })
  hl('@text.environment', { link = 'Macro' })
  hl('@text.environment.name', { link = 'Type' })
  hl('@text.reference', { link = 'Constant' })

  hl('@text.todo', { link = 'Todo' })
  hl('@text.note', { link = 'SpecialComment' })
  hl('@text.warning', { link = 'WarningMsg' })
  hl('@text.danger', { link = 'ErrorMsg' })
  -- }}}

  -- Tags {{{
  hl('@tag', { link = 'Tag' })
  hl('@tag.attribute', { link = 'Identifier' })
  hl('@tag.delimiter', { link = 'Delimiter' })
  -- }}}

  -- Customs {{{
  hl('@illuminate', ILLUMINATION)
  -- }}}
end

local function set_colorscheme(nm, force)
  if not force and nm == api.nvim_exec('colorscheme', true) then
    return
  end
  vim.cmd('colorscheme ' .. nm)
  require('hlargs').setup()
  require('colorizer').setup()
  require('lsp-colors').setup()
  api.nvim_set_hl(0, "IlluminatedWordText", ILLUMINATION)
  api.nvim_set_hl(0, "IlluminatedWordRead", ILLUMINATION)
  api.nvim_set_hl(0, "IlluminatedWordWrite", ILLUMINATION)
  -- api.nvim_set_hl(0, "Folded", ILLUMINATION)
  api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
  hl_treesitter()
end

-- Update colorscheme when buffer is outside of cwd
local function set_autocmd()
  local GROUP = api.nvim_create_augroup('theme-custom', {})
  api.nvim_create_autocmd('TabEnter', {
    group = GROUP,
    nested = true,
    callback = function(_)
      set_colorscheme(
        (api.nvim_get_current_tabpage() == 1) and DEFAULT_COLORSCHEME or TAB_COLORSCHEME
      )
    end
  })
  api.nvim_create_autocmd(
    'BufEnter',
    {
      group = GROUP,
      nested = true,
      desc = 'Change theme by the path of the current buffer.',
      callback = function(args)
        if api.nvim_get_current_tabpage() ~= 1 then return end
        if api.nvim_buf_get_option(0, "buftype") ~= '' then return end
        if args.file == '' or vim.startswith(args.file, fn.getcwd() .. '/') then return end

        -- Apply colorscheme and some highlight settings
        require('styler').set_theme(0, { colorscheme = OUTSIDE_COLORSCHEME })
      end
    }
  )
end

-- return
return {
  deps = {
    -- { '4513ECHO/vim-colors-hatsunemiku' },
    -- { 'ellisonleao/gruvbox.nvim' },
    -- { 'sainnhe/everforest' },
    { 'm-demare/hlargs.nvim' },
    { 'RRethy/vim-illuminate' },
    { 'norcalli/nvim-colorizer.lua' },
    { 'folke/lsp-colors.nvim' },
    { 'folke/styler.nvim' },
    { "catppuccin/nvim", as = "catppuccin" },
    { "EdenEast/nightfox.nvim" },
    -- { "RRethy/nvim-base16" },
  },
  setup = function()
    set_colorscheme(DEFAULT_COLORSCHEME, true)
    set_autocmd()
  end
}
