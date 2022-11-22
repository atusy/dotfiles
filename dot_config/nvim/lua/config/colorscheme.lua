-- const
local api = vim.api
local DEFAULT_COLORSCHEME = 'hatsunemiku'
local OUTSIDE_COLORSCHEME = 'gruvbox'
local TAB_COLORSCHEME = 'everforest'
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

local function set_colorscheme(nm, force, opt)
  if not force and nm == api.nvim_exec('colorscheme', true) then
    return
  end
  vim.cmd('colorscheme ' .. nm)
  require('hlargs').setup()
  require('colorizer').setup()
  require('lsp-colors').setup()
  local illumination = opt.illumination or ILLUMINATION
  api.nvim_set_hl(0, "IlluminatedWordText", illumination)
  api.nvim_set_hl(0, "IlluminatedWordRead", illumination)
  api.nvim_set_hl(0, "IlluminatedWordWrite", illumination)
  api.nvim_set_hl(0, "Folded", illumination)
  api.nvim_set_hl(0, 'LeapBackdrop', vim.api.nvim_get_hl_by_name('Comment', true))
  hl_treesitter()
end

-- Update colorscheme when buffer is outside of cwd
local function set_autocmd(opt)
  local DEFAULT = opt.colorscheme.default or DEFAULT_COLORSCHEME
  local OUTSIDE = opt.colorscheme.outside or OUTSIDE_COLORSCHEME
  local TAB = opt.colorscheme.tab or TAB_COLORSCHEME
  local GROUP = api.nvim_create_augroup('theme-custom', {})
  api.nvim_create_autocmd(
    'Filetype',
    {
      desc = 'Fix colorscheme if filetype is set after bufenter',
      group = GROUP,
      nested = true,
      pattern = { 'help' },
      callback = function(args)
        if api.nvim_get_current_tabpage() ~= 1 then
          set_colorscheme(TAB, false, opt)
          return
        end
        set_colorscheme(DEFAULT, false, opt)
      end
    }
  )
  api.nvim_create_autocmd(
    'BufEnter',
    {
      group = GROUP,
      nested = true,
      desc = 'Change theme by the path of the current buffer.',
      callback = function(args)
        if api.nvim_get_current_tabpage() ~= 1 then
          set_colorscheme(TAB, false, opt)
          return
        end
        local FILE = args.file
        local FILETYPE = api.nvim_buf_get_option(0, "filetype")
        local BUFTYPE = api.nvim_buf_get_option(0, "buftype")
        local CWD = vim.fn.getcwd()
        local COLORSCHEME = (
            FILE == '' or
                FILETYPE == 'gitcommit' or
                FILETYPE == 'gitrebase' or
                FILETYPE == 'help' or
                BUFTYPE ~= '' or
                CWD == string.sub(FILE, 1, string.len(CWD)) or
                '/tmp/' == string.sub(FILE, 1, 5)
            ) and DEFAULT or OUTSIDE

        -- Apply colorscheme and some highlight settings
        set_colorscheme(COLORSCHEME, false, opt)
      end
    }
  )
end

-- return
return {
  deps = {
    { '4513ECHO/vim-colors-hatsunemiku' },
    { 'morhetz/gruvbox' },
    { 'sainnhe/everforest' },
    { 'm-demare/hlargs.nvim' },
    { 'RRethy/vim-illuminate' },
    { 'norcalli/nvim-colorizer.lua' },
    { 'folke/lsp-colors.nvim' },
  },
  setup = function(opt)
    opt = opt or { colorscheme = {} }
    set_colorscheme(opt.colorscheme.default or DEFAULT_COLORSCHEME, true, opt)
    set_autocmd(opt)
  end
}
