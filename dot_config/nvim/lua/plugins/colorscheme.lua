-- const
local api = vim.api
local utils = require("atusy.utils")
local ACTIVE_COLORSCHEME = "duskfox" -- for the active buffer the first tabpage
local INACTIVE_COLORSCHEME = "nordfox"
local OUTSIDE_COLORSCHEME = "carbonfox"
local TAB_COLORSCHEME = "terafox" -- for the active buffer in the other tabpages

local function likely_cwd(buf)
  buf = buf or api.nvim_win_get_buf(0)
  if api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then
    return true
  end

  local file = api.nvim_buf_get_name(buf)
  return file == "" or require("atusy.misc").in_cwd(file)
end

local function set_theme(win, colorscheme)
  if colorscheme == vim.g.colors_name then
    -- if default colorscheme, clear() should be enough
    require("styler").clear(win)
  elseif colorscheme ~= (vim.w[win].theme or {}).colorscheme then
    require("styler").set_theme(win, { colorscheme = colorscheme })
  end
end

local function theme_active_win(win, tab)
  -- use default colorscheme on floating windows
  if api.nvim_win_get_config(win).relative ~= "" then
    return
  end

  -- apply colorscheme
  local COLORSCHEME = ACTIVE_COLORSCHEME
  if tab ~= 1 then
    COLORSCHEME = TAB_COLORSCHEME
  elseif not likely_cwd(api.nvim_win_get_buf(win)) then
    COLORSCHEME = OUTSIDE_COLORSCHEME
  end
  set_theme(win, COLORSCHEME)
end

local function theme_inactive_win(win, tab)
  -- skip for certain situations
  if not api.nvim_win_is_valid(win) then
    return
  end
  if api.nvim_win_get_config(win).relative ~= "" then
    return
  end

  -- apply colorscheme
  local COLORSCHEME = INACTIVE_COLORSCHEME
  if tab == 1 and not likely_cwd(api.nvim_win_get_buf(win)) then
    COLORSCHEME = OUTSIDE_COLORSCHEME
  end
  set_theme(win, COLORSCHEME)
end

local function theme()
  local win_cursor = api.nvim_get_current_win()
  local tab = api.nvim_get_current_tabpage()

  -- Activate
  theme_active_win(win_cursor, tab)

  for _, w in pairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if w ~= win_cursor then
      theme_inactive_win(w, tab)
    end
  end

  -- redraw is required for instant theming on CmdlineEnter
  -- after closing of focused floating windows,
  vim.cmd([[redraw]])
end

local state = {}

local function set_styler()
  api.nvim_create_autocmd({
    "BufWinEnter", -- instead of BufEnter
    "WinEnter",
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
    callback = function()
      -- only apply theme from the latest schedule
      for k, _ in pairs(state) do
        state[k] = nil
      end
      local key = tostring(math.random())
      state[key] = true
      vim.schedule(function()
        if state[key] then
          theme()
          require("atusy.highlight").change_background(require("atusy.highlight").transparent)
        end
      end)
    end,
  })
end

-- return
return {
  -- { '4513ECHO/vim-colors-hatsunemiku' },
  -- { 'ellisonleao/gruvbox.nvim' },
  -- { 'sainnhe/everforest' },
  -- { "https://github.com/catppuccin/nvim", as = "catppuccin" },
  -- { 'levouh/tint.nvim' }, -- conflicts with styler.nvim
  -- { "https://github.com/RRethy/nvim-base16" },
  {
    "https://github.com/m-demare/hlargs.nvim",
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
    "https://github.com/RRethy/vim-illuminate",
    -- or https://github.com/tzachar/local-highlight.nvim
    lazy = true,
    event = "BufReadPre",
    dependencies = { "https://github.com/nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.keymap.set("n", "<Left>", function()
        require("illuminate").goto_prev_reference()
      end)
      vim.keymap.set("n", "<Right>", function()
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
    "https://github.com/norcalli/nvim-colorizer.lua",
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
    "https://github.com/folke/styler.nvim",
    event = { "WinNew", "BufRead", "BufNewFile" },
    dependencies = { "https://github.com/EdenEast/nightfox.nvim" },
    config = function()
      set_styler()
    end,
  },
  {
    "https://github.com/EdenEast/nightfox.nvim",
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
      vim.schedule(function()
        if vim.env.NVIM_TRANSPARENT == "1" then
          require("atusy.highlight").remove_background(0)
        end
      end)
    end,
  },
}
