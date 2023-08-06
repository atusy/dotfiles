-- const
local api = vim.api
local fn = vim.fn
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap
local ACTIVE_COLORSCHEME = "duskfox" -- for the active buffer the first tabpage
local INACTIVE_COLORSCHEME = "nordfox"
local OUTSIDE_COLORSCHEME = "carbonfox"
local TAB_COLORSCHEME = "terafox" -- for the active buffer in the other tabpages

local function in_cwd(path)
  return path == "" or vim.startswith(path, fn.getcwd() .. "/")
end

local function likely_cwd(buf)
  buf = buf or api.nvim_win_get_buf(0)
  if api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then
    return true
  end

  local ft = vim.api.nvim_get_option_value("filetype", {
    buf = buf,
  })
  if ft == "oil" then
    -- current implementation only works on entering oil
    -- not on directory navigations
    return in_cwd(require("oil").get_current_dir())
  end

  local file = api.nvim_buf_get_name(buf)
  return in_cwd(file)
end

local function set_theme(win, colorscheme)
  if colorscheme == vim.g.colors_name then
    -- if default colorscheme, clear() should be enough
    require("styler").clear(win)
  elseif colorscheme ~= (vim.w[win].theme or {}).colorscheme then
    require("styler").set_theme(win, { colorscheme = colorscheme })
  end
end

local function theme_active_win(win)
  -- use default colorscheme on floating windows
  if api.nvim_win_get_config(win).relative ~= "" then
    return
  end

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
  if not api.nvim_win_is_valid(win) then
    return
  end
  if api.nvim_win_get_config(win).relative ~= "" then
    return
  end

  -- apply colorscheme
  local COLORSCHEME = INACTIVE_COLORSCHEME
  if (api.nvim_get_current_tabpage() == 1) and (not likely_cwd(api.nvim_win_get_buf(win))) then
    COLORSCHEME = OUTSIDE_COLORSCHEME
  end
  set_theme(win, COLORSCHEME)
end

local function theme(win_event)
  local win_pre = fn.win_getid(fn.winnr("#"))
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

  -- redraw is required for instant theming on CmdlineEnter
  -- after closing of focused floating windows,
  vim.cmd([[redraw]])
end

local function set_styler()
  api.nvim_create_autocmd({
    "BufWinEnter", -- instead of BufEnter
    "WinLeave", -- supports changes without WinEnter (e.g., cmdbuf.nvim)
    "WinNew", -- supports new windows without focus (e.g., `vim.api.nvim_win_call(0, vim.cmd.vsplit)`)
    "WinClosed", --[[
        supports active window being closed via win_call
            ``` vim
            vsplit
            lua (function(w) vim.api.nvim_win_call(vim.fn.win_getid(vim.fn.winnr('#')), function() vim.api.nvim_win_close(w, true) end) end)(vim.api.nvim_get_current_win())
            ```
      ]]
  }, {
    group = utils.augroup,
    callback = function(_)
      local win_event = api.nvim_get_current_win()
      vim.schedule(function()
        theme(win_event)
      end)
    end,
  })
end

-- return
return {
  -- { '4513ECHO/vim-colors-hatsunemiku' },
  -- { 'ellisonleao/gruvbox.nvim' },
  -- { 'sainnhe/everforest' },
  -- { "catppuccin/nvim", as = "catppuccin" },
  -- { 'levouh/tint.nvim' }, -- conflicts with styler.nvim
  -- { "RRethy/nvim-base16" },
  {
    "m-demare/hlargs.nvim",
    -- maybe nolonger used because @parameter highlights well, also conflicts with neodim
    -- event = 'BufReadPre',
    cond = false,
    lazy = true,
    config = function()
      local function setup()
        require("hlargs").setup()
      end

      vim.api.nvim_create_autocmd("ColorScheme", { group = utils.augroup, callback = setup })
      setup()
    end,
  },
  {
    "RRethy/vim-illuminate",
    -- or https://github.com/tzachar/local-highlight.nvim
    lazy = true,
    event = "BufReadPre",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      set_keymap("n", "<Left>", function()
        require("illuminate").goto_prev_reference()
      end)
      set_keymap("n", "<Right>", function()
        require("illuminate").goto_next_reference()
      end)
    end,
    config = function()
      local function hi()
        -- @illuminate is defined on configure of treesitter
        api.nvim_set_hl(0, "IlluminatedWordText", { link = "@illuminate" })
        api.nvim_set_hl(0, "IlluminatedWordRead", { link = "@illuminate" })
        api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "@illuminate" })
      end

      require("illuminate").configure({
        filetype_denylist = { "fern" },
        modes_allowlist = { "n" },
      })
      vim.api.nvim_create_autocmd("ColorScheme", { group = utils.augroup, callback = hi })
      hi()
    end,
  },
  {
    "norcalli/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      local function setup()
        require("colorizer").setup()
      end

      vim.api.nvim_create_autocmd("ColorScheme", { group = utils.augroup, callback = setup })
      setup()
    end,
  },
  {
    "folke/styler.nvim",
    event = { "WinNew", "BufRead", "BufNewFile" },
    dependencies = { "EdenEast/nightfox.nvim" },
    config = function()
      set_styler()
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 9999,
    config = function()
      require("nightfox").setup({
        groups = {
          all = {
            ["@text.literal"] = { link = "String" },
            NvimTreeNormal = { link = "Normal" },
          },
        },
        options = { inverse = { visual = true } },
      })
      vim.cmd.colorscheme("duskfox")
    end,
  },
}
