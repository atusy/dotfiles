local vim = vim
local api = vim.api

local utils = require('utils')
local _require = utils.require
local set_keymap = utils.set_keymap

-- gitsigns settings
local function setup_gitsigns()
  local gs = require('gitsigns')
  local has_num = vim.opt.number:get() or vim.opt.relativenumber:get()
  gs.setup({
    signcolumn = not has_num,
    numhl = has_num,
    current_line_blame_opts = {
      delay = 150
    },
    on_attach = function(bufnr)
      local OPTS = { buffer = bufnr }
      set_keymap('v', '<C-G><C-A>', gs.stage_hunk, OPTS, { desc = "git add visual selection" })
      set_keymap('n', '<Plug>(C-G)<C-A>', gs.stage_hunk, OPTS, { desc = "git add hunk" })
      set_keymap('n', '<Plug>(C-G)a', gs.stage_buffer, OPTS, { desc = "git add buffer" })
      set_keymap('n', '<Plug>(C-G)<C-R>', gs.reset_hunk, OPTS, { desc = "git reset hunk" })
      set_keymap('n', '<Plug>(C-G)r', gs.reset_buffer, OPTS, { desc = "git reset buffer" })
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
  -- disable delta as <CR> won't work
  --[[ if has_delta then
    vim.g.gin_diff_default_args = { "++processor=delta" }
  end ]]
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
  set_keymap('n', 'dd', 'dd') -- workaround waiting dd after GinPatch
  set_keymap('n', '<Plug>(C-G)<C-P>', '<Cmd>GinPatch ++opener=tabnew %<CR>')
  local graph = function(opts)
    opts = opts and (" " .. opts) or ""
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "gintonic-graph" then
      opts = [[ ++opener=rightbelow\ vsplit --first-parent]] .. opts
    end
    vim.cmd("GintonicGraph" .. opts)
  end
  set_keymap('n', '<Plug>(C-G)<C-L>', function() graph() end, { desc = "git graph" }) -- git log --graph ...
  set_keymap('n', '<Plug>(C-G)%', function() graph("-- %") end, { desc = "git graph current buffer" })
  -- following keymaps exists as snippets, and thus ends with space rather than <CR>
  set_keymap('n', '<Plug>(git-amend)', ':Gin commit --amend ')
  set_keymap('n', '<Plug>(git-amend-no-edit)', ':Gin commit --amend --no-edit ')
  set_keymap('n', '<Plug>(git-rebase-i)', ':Gin rebase -i ')
  set_keymap('n', '<Plug>(git-push-origin)', ':Gin push origin HEAD ')
end

-- return
return {
  deps = {
    { 'lambdalisue/gin.vim' },
    { 'tpope/vim-fugitive' },
    { 'knsh14/vim-github-link' },
    -- { 'tanvirtin/vgit.nvim' },
    { 'nvim-lua/plenary.nvim' }, -- for vgit
    { 'vim-denops/denops.vim' }, -- for gin
    { 'lewis6991/gitsigns.nvim' },
  },
  setup = function(_)
    setup_gin()
    setup_gitsigns()

    -- fugitive
    set_keymap('n', '<Plug>(C-G)<C-Space>', [[<Cmd>Git commit<CR>]])
  end
}
