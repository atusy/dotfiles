-- const
local api = vim.api
local DEFAULT_COLORSCHEME = 'hatsunemiku'
local OUTSIDE_COLORSCHEME = 'gruvbox'
local TAB_COLORSCHEME = 'everforest'
local ILLUMINATION = {bg="#383D47"}

-- set colorscheme
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
end

-- Update colorscheme when buffer is outside of cwd
local function set_autocmd(opt)
  local DEFAULT = opt.colorscheme.default or DEFAULT_COLORSCHEME
  local OUTSIDE = opt.colorscheme.outside or OUTSIDE_COLORSCHEME
  local TAB = opt.colorscheme.tab or TAB_COLORSCHEME
  local GROUP = api.nvim_create_augroup('theme-custom', {})
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
    {'4513ECHO/vim-colors-hatsunemiku'},
    {'morhetz/gruvbox'},
    {'sainnhe/everforest'},
    {'m-demare/hlargs.nvim'},
    {'RRethy/vim-illuminate'},
    {'norcalli/nvim-colorizer.lua'},
    {'folke/lsp-colors.nvim'},
  },
  setup = function(opt)
    opt = opt or {colorscheme = {}}
    set_colorscheme(opt.colorscheme.default or DEFAULT_COLORSCHEME, true, opt)
    set_autocmd(opt)
  end
}
