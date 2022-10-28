local vim = vim
local api = vim.api

local utils = require('utils')
local _require = utils.require
local set_keymap = utils.set_keymap

-- vgit
local function setup_vgit()
  local Vgit = require 'vgit'
  Vgit.setup {
    keymaps = {},
    settings = {
      live_blame = {
        enabled = false
      },
      live_gutter = {
        enabled = true
      },
      signs = {
        priority = 10,
        definitions = {
          GitSignsAdd = {
            texthl = 'GitSignsAdd',
            numhl = 'GitSignsAdd',
            icon = nil,
            linehl = nil,
            text = '',
          },
          GitSignsDelete = {
            texthl = 'GitSignsDelete',
            numhl = 'GitSignsDelete',
            icon = nil,
            linehl = nil,
            text = '',
          },
          GitSignsChange = {
            texthl = 'GitSignsChange',
            numhl = 'GitSignsChange',
            icon = nil,
            linehl = nil,
            text = '',
          },
        },
      },
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
  set_keymap('n', '<Plug>(C-G)a', '<Plug>(vgit.buffer_stage)')
  set_keymap('n', '<Plug>(C-G)<C-A>', '<Plug>(vgit.buffer_hunk_stage)')
end

local setup_gitsigns = function()
  local gs = require('gitsigns')
  gs.setup({
    signcolumn = false,
    numhl = true,
    current_line_blame_opts = {
      delay = 150
    },
    on_attach = function(bufnr)
      local OPTS = { buffer = bufnr }
      set_keymap({ 'n', 'v' }, '<Plug>(C-G)<C-A>', gs.stage_hunk, OPTS)
      set_keymap('n', '<Plug>(C-G)a', gs.stage_buffer, OPTS)
      set_keymap({ 'n', 'v' }, '<Plug>(C-G)<C-R>', gs.reset_hunk, OPTS)
      set_keymap('n', '<Plug>(C-G)r', gs.reset_buffer, OPTS)
      set_keymap(
        'n', '<Plug>(toggle-live-git-blame)',
        function()
          vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "Comment" })
          gs.toggle_current_line_blame()
        end,
        OPTS
      )

      set_keymap(
        'n', '<Down>',
        function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end,
        { expr = true }
      )

      set_keymap(
        'n', '<Up>',
        function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end,
        { expr = true }
      )
    end
  })
end
-- gin & gintonic
local function setup_gin()
  local has_delta = vim.fn.executable('delta') == 1
  if has_delta then
    vim.g.gin_diff_default_args = { "++processor=delta" }
  end
  _require("gintonic").setup({
    params = {
      GinBuffer = { processor = has_delta and "delta" or nil }
    }
  })
  local augroup_gin = api.nvim_create_augroup("gin-custom", {})
  api.nvim_create_autocmd(
    "FileType",
    {
      group = augroup_gin,
      pattern = "gin-patch",
      callback = function()
        set_keymap("n", "<Plug>(C-G)<C-A>", "<Plug>(gin-diffget-r)", { bufnr = 0 }) -- git add
        set_keymap("n", "<Plug>(C-G)<C-R>", "<Plug>(gin-diffget-l)", { bufnr = 0 }) -- git reset
      end
    }
  )
  api.nvim_create_autocmd(
    "FileType",
    {
      group = augroup_gin,
      pattern = "gintonic-graph",
      callback = function() vim.opt_local.cursorline = true end
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
      opts = [[ ++opener=rightbelow\ vsplit --first-parent]] .. opts
    end
    vim.cmd("GintonicGraph" .. opts)
  end
  set_keymap('n', '<Plug>(C-G)<C-L>', function() graph() end, {desc = "git graph"}) -- git log --graph ...
  set_keymap('n', '<Plug>(C-G)%', function() graph("-- %") end, {desc = "git graph current buffer"})
end

-- return
return {
  deps = {
    { 'lambdalisue/gin.vim' },
    { 'tpope/vim-fugitive' },
    { 'knsh14/vim-github-link' },
    { 'tanvirtin/vgit.nvim' },
    { 'nvim-lua/plenary.nvim' }, -- for vgit
    { 'vim-denops/denops.vim' }, -- for gin
    { 'lewis6991/gitsigns.nvim' },
  },
  setup = function(_)
    -- setup_vgit()
    setup_gin()
    setup_gitsigns()
    -- require('gitsigns').setup({signcolumn = false, numhl = true})

    -- fugitive
    set_keymap('n', '<Plug>(C-G)<C-Space>', [[<Cmd>Git commit<CR>]])
  end
}
