local vim = vim
local api = vim.api

local utils = require('utils')
local _require = utils.require
local set_keymap = utils.set_keymap

-- vgit
local function setup_vgit()
  local Vgit = require'vgit'
  Vgit.setup {
    keymaps = {},
    settings = {
      live_blame = {
        enabled = false
      }
    }
  }
  api.nvim_create_user_command('ToggleBlame', Vgit.toggle_live_blame, {})
  for k, f in pairs(Vgit) do
    if type(f) == "function" then
      set_keymap('n', '<Plug>(vgit.' .. k .. ')', function() f() end)
    end
  end
  set_keymap('n', '<Up>', '<Plug>(vgit.hunk_up)')
  set_keymap('n', '<Down>', '<Plug>(vgit.hunk_down)')
  set_keymap('n', '<Plug>(C-G)<C-R>', '<Plug>(vgit.buffer_hunk_reset)')
  set_keymap('n', '<Plug>(C-G)a', '<Cmd>w<CR><Plug>(vgit.buffer_stage)')
  set_keymap('n', '<Plug>(C-G)<C-A>', '<Cmd>w<CR><Plug>(vgit.buffer_hunk_stage)')
end

-- gin & gintonic
local function setup_gin()
  local has_delta = vim.fn.executable('delta') == 1
  if has_delta then
    vim.g.gin_diff_default_args = {"++processor=delta"}
  end
  _require("gintonic").setup({
    params = {
      GinBuffer = {processor = has_delta and "delta" or nil}
    }
  })
  local augroup_gin = api.nvim_create_augroup("gin-custom", {})
  api.nvim_create_autocmd(
    "FileType",
    {
      group = augroup_gin,
      pattern = "gin-patch",
      callback = function()
        set_keymap("n", "<Plug>(C-G)<C-A>", "<Plug>(gin-diffget-r)", {bufnr = 0}) -- git add
        set_keymap("n", "<Plug>(C-G)<C-R>", "<Plug>(gin-diffget-l)", {bufnr = 0}) -- git reset
      end
    }
  )
  api.nvim_create_autocmd(
    "FileType",
    {
      group = augroup_gin,
      pattern = "gintonic-graph",
      callback = function()
        vim.opt_local.cursorline = true
      end
    }
  )
  api.nvim_exec([[
    cabbrev GinGraph GintonicGraph
    cabbrev GitGraph GintonicGraph
  ]], false)
  set_keymap('n', '<Plug>(C-G)<C-P>', '<Cmd>GinPatch ++opener=tabnew %<CR>')
  local graph = function(opts)
    opts = opts and (" " .. opts) or ""
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "gintonic-graph" then
      opts = [[ ++opener=botright\ vsplit --first-parent]] .. opts
    end
    vim.cmd("GintonicGraph" .. opts)
  end
  set_keymap('n', '<Plug>(C-G)<C-L>', function() graph() end) -- git log --graph ...
  set_keymap('n', '<Plug>(C-G)%', function() graph("-- %") end)
end

-- return
return {
  deps = {
    {'lambdalisue/gin.vim'},
    {'tpope/vim-fugitive'},
    {'knsh14/vim-github-link'},
    {'tanvirtin/vgit.nvim'},
    {'nvim-lua/plenary.nvim'}, -- for vgit
    {'vim-denops/denops.vim'}, -- for gin
  },
  setup = function(_)
    setup_vgit()
    setup_gin()
    -- fugitive
    set_keymap('n', '<Plug>(C-G)<C-Space>', [[<Cmd>Git commit<CR>]])
  end
}
