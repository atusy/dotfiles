-- const
local api = vim.api
local fn = vim.fn
local utils = require('utils')
local set_keymap = utils.set_keymap
local DEFAULT_COLORSCHEME = 'duskfox'
local ACTIVE_COLORSCHEME = 'duskfox' -- for the active buffer the first tabpage
local INACTIVE_COLORSCHEME = 'nordfox'
local OUTSIDE_COLORSCHEME = 'carbonfox'
local TAB_COLORSCHEME = 'terafox' -- for the active buffer in the other tabpages
local ILLUMINATION = { bg = "#383D47" }

local function set_colorscheme(nm)
  local function colorscheme_post()
    -- require('atusy.ts-highlight').setup()
    require('hlargs').setup()
    require('colorizer').setup()
    require('lsp-colors').setup()
    api.nvim_set_hl(0, "IlluminatedWordText", ILLUMINATION)
    api.nvim_set_hl(0, "IlluminatedWordRead", ILLUMINATION)
    api.nvim_set_hl(0, "IlluminatedWordWrite", ILLUMINATION)
    api.nvim_set_hl(0, "@illuminate", ILLUMINATION)

    local has_tsht, _ = pcall(require, 'tsht')
    if has_tsht then
      api.nvim_set_hl(0, 'TSNodeUnmatched', { link = 'Comment' })
      api.nvim_set_hl(0, 'TSNodeKey', { link = 'IncSearch' })
    end

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
        set_keymap('n', '<Left>', Illuminate.goto_prev_reference, { desc = 'previous references' })
        set_keymap('n', '<Right>', Illuminate.goto_next_reference, { desc = 'next reference' })
      end
    },
    { 'norcalli/nvim-colorizer.lua' },
    { 'folke/lsp-colors.nvim' },
    { 'folke/styler.nvim' },
    -- { "catppuccin/nvim", as = "catppuccin" },
    {
      "EdenEast/nightfox.nvim",
      lazy = false,
      priority = 9999,
      build = function()
        -- thanks to cache, this needs run only on build (unless changed)
        require('nightfox').setup({
          groups = { all = { ['@text.literal'] = { link = 'String' } } },
          options = {
            inverse = {
              visual = true,
            },
          },
        })
      end
    },
    -- { 'levouh/tint.nvim' }, -- conflicts with styler.nvim
    -- { "RRethy/nvim-base16" },
  },
  setup = function()
    set_colorscheme(DEFAULT_COLORSCHEME)
    set_styler()
  end
}
