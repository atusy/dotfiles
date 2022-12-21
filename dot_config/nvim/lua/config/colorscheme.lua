-- const
local api = vim.api
local fn = vim.fn
local utils = require('utils')
local DEFAULT_COLORSCHEME = 'duskfox'
local ACTIVE_COLORSCHEME = 'duskfox' -- for the active buffer the first tabpage
local INACTIVE_COLORSCHEME = 'nordfox'
local OUTSIDE_COLORSCHEME = 'carbonfox'
local TAB_COLORSCHEME = 'terafox' -- for the active buffer in the other tabpages
local ILLUMINATION = { bg = "#383D47" }

-- set colorscheme
local function hl_treesitter(enable)
  if not enable then return end
  local function hl(group, opts)
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
end

local function set_colorscheme(nm)
  local function colorscheme_post()
    hl_treesitter(false)
    require('hlargs').setup()
    require('colorizer').setup()
    require('lsp-colors').setup()
    api.nvim_set_hl(0, "IlluminatedWordText", ILLUMINATION)
    api.nvim_set_hl(0, "IlluminatedWordRead", ILLUMINATION)
    api.nvim_set_hl(0, "IlluminatedWordWrite", ILLUMINATION)
    api.nvim_set_hl(0, "@illuminate", ILLUMINATION)
    local has_leap, leap = pcall(require, 'leap')
    if has_leap then
      api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
      leap.init_highlight(true)
    end
  end

  -- apply colorscheme
  vim.cmd('colorscheme ' .. nm)
  colorscheme_post()

  -- add autocmd
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = utils.augroup, callback = colorscheme_post, pattern = '*'
  })
end

local function likely_cwd(buf)
  buf = buf or api.nvim_win_get_buf(0)
  if api.nvim_buf_get_option(buf, "buftype") ~= '' then return true end

  local file = api.nvim_buf_get_name(buf)
  return file == '' or vim.startswith(file, fn.getcwd() .. '/')
end

local function set_theme(win, colorscheme)
  if colorscheme == DEFAULT_COLORSCHEME then
    -- if default colorscheme, clear() should be enough
    require('styler').clear(win)
  elseif colorscheme ~= (vim.w[win].theme or {}).colorscheme then
    require('styler').set_theme(win, { colorscheme = colorscheme })
  end
end

local function theme_active_win(win)
  -- use default colorscheme on floating windows
  if api.nvim_win_get_config(win).relative ~= "" then return end

  -- apply colorscheme
  local COLORSCHEME = ACTIVE_COLORSCHEME
  if api.nvim_get_current_tabpage() ~= 1 then
    COLORSCHEME = TAB_COLORSCHEME
  elseif not likely_cwd(api.nvim_win_get_buf(win)) then
    COLORSCHEME = OUTSIDE_COLORSCHEME
  end
  set_theme(win, COLORSCHEME)
end

local function theme_inactive_win(win)
  -- skip for certain situations
  if not api.nvim_win_is_valid(win) then return end
  if api.nvim_win_get_config(win).relative ~= "" then return end

  -- apply colorscheme
  local COLORSCHEME = INACTIVE_COLORSCHEME
  if (api.nvim_get_current_tabpage() == 1) and (not likely_cwd(api.nvim_win_get_buf(win))) then
    COLORSCHEME = OUTSIDE_COLORSCHEME
  end
  set_theme(win, COLORSCHEME)
end

local function set_styler()
  api.nvim_create_autocmd(
    {
      'BufWinEnter', -- instead of BufEnter
      'WinLeave', -- supports changes without WinEnter (e.g., cmdbuf.nvim)
      'WinNew', -- supports new windows without focus (e.g., `vim.api.nvim_win_call(0, vim.cmd.vsplit)`)
    },
    {
      group = utils.augroup,
      callback = function(_)
        local win_event = api.nvim_get_current_win()
        vim.schedule(function()
          local win_pre = fn.win_getid(fn.winnr('#'))
          local win_cursor = api.nvim_get_current_win()

          -- Activate
          theme_active_win(win_cursor)

          -- Deactivate previous window
          if win_pre ~= 0 and win_pre ~= win_cursor then
            theme_inactive_win(win_pre)
          end

          -- Deactivate an inactive window that triggered BufWinEnter
          if win_event ~= win_cursor then
            theme_inactive_win(win_event)
          end
        end)
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
    {
      'RRethy/vim-illuminate',
      config = function()
        local Illuminate = require 'illuminate'
        Illuminate.configure({
          filetype_denylist = { 'fugitive', 'fern' },
          modes_allowlist = { 'n' }
        })
        set_keymap('n', '<C-H>', Illuminate.goto_prev_reference, { desc = 'previous references' })
        set_keymap('n', '<C-L>', Illuminate.goto_next_reference, { desc = 'next reference' })
      end
    },
    { 'norcalli/nvim-colorizer.lua' },
    { 'folke/lsp-colors.nvim' },
    { 'folke/styler.nvim' },
    -- { "catppuccin/nvim", as = "catppuccin" },
    { "EdenEast/nightfox.nvim" },
    -- { 'levouh/tint.nvim' }, -- conflicts with styler.nvim
    -- { "RRethy/nvim-base16" },
  },
  setup = function()
    require('nightfox').setup({
      groups = { all = { ['@text.literal'] = { link = 'String' } } }
    })
    set_colorscheme(DEFAULT_COLORSCHEME)
    set_styler()
  end
}
