local api = vim.api

local utils = require("atusy.utils")
local _require = utils.require
local set_keymap = utils.set_keymap
local add_palette = require("atusy.keymap.palette").add_item

-- gitsigns settings
local function setup_gitsigns()
  local gs = require("gitsigns")
  local has_num = vim.opt.number:get() or vim.opt.relativenumber:get()
  local function after_save(x, cmd)
    return "<Plug>(save)" .. (cmd or "<Cmd>") .. "Gitsigns " .. x .. "<CR>"
  end

  vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "Comment" })
  add_palette("n", "toggle current line git blame", "<Cmd>Gitsigns toggle_current_line_blame<CR>")

  gs.setup({
    signcolumn = not has_num,
    numhl = has_num,
    current_line_blame_opts = {
      delay = 150,
    },
    on_attach = function(bufnr)
      local OPTS = { buffer = bufnr, fav = "false" }
      set_keymap("x", "<Plug>(C-G)<C-A>", after_save("stage_hunk", [[<C-\><C-N>gv:]]), OPTS, { desc = "git add hunk" })
      set_keymap("n", "<Plug>(C-G)<C-A>", after_save("stage_hunk"), OPTS, { desc = "git add hunk" })
      set_keymap("n", "<Plug>(C-G)a", after_save("stage_buffer"), OPTS, { desc = "git add buffer" })
      set_keymap("n", "<Plug>(C-G)<C-R>", after_save("reset_hunk"), OPTS, { desc = "git reset hunk" })
      set_keymap("x", "<Plug>(C-G)<C-R>", after_save("reset_hunk", ":"), OPTS, { desc = "git reset hunk" })
      set_keymap("n", "<Plug>(C-G)r", after_save("reset_buffer"), OPTS, { desc = "git reset buffer" })
      set_keymap("n", "<Plug>(C-G)<C-H>", after_save("preview_hunk"), OPTS, { desc = "git preview hunk" })

      set_keymap("n", "<Down>", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })

      set_keymap("n", "<Up>", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true })
    end,
  })
  add_palette("n", "gitsigns based on cWORD ref", function()
    require("gitsigns").change_base(vim.fn.expand("<cWORD>"), true)
  end)
  add_palette("n", "gitsigns based on HEAD", function()
    require("gitsigns").reset_base(true)
  end)
  add_palette("n", "gitsigns qflist", function()
    require("gitsigns").setqflist("all")
  end)
  add_palette("n", "gitsigns toggle word diff", function()
    require("gitsigns").toggle_word_diff()
  end)
  add_palette("n", "gitsings undo add hunk", function()
    require("gitsings").undo_stage_hunk()
  end)
end

-- gin & gintonic
local function setup_gin()
  local has_delta = vim.fn.executable("delta") == 1
  -- disable delta as <CR> won't work
  local processor = nil
  if has_delta then
    processor = "delta --diff-highlight --keep-plus-minus-markers"
    vim.g.gin_diff_default_args = { "++processor=" .. processor }
  end
  _require("gintonic").setup({
    params = {
      GinBuffer = { processor = processor },
    },
  })
  api.nvim_create_autocmd("FileType", {
    group = utils.augroup,
    pattern = "gin-patch",
    callback = function()
      set_keymap("n", "<Plug>(C-G)<C-A>", "<Plug>(gin-diffget-r)", { bufnr = 0 }) -- git add
      set_keymap("n", "<Plug>(C-G)<C-R>", "<Plug>(gin-diffget-l)", { bufnr = 0 }) -- git reset
    end,
  })
  api.nvim_create_autocmd("FileType", {
    group = utils.augroup,
    pattern = "gintonic-graph",
    callback = function()
      vim.opt_local.cursorline = true
    end,
  })
  api.nvim_create_autocmd("FileType", {
    group = utils.augroup,
    pattern = "gitcommit",
    callback = function()
      vim.g.gin_proxy_apply_without_confirm = 1
      vim.cmd([[cabbrev <buffer> <expr> q! (getcmdtype() ==# ':' && getcmdline() ==# 'q!') ? 'up <Bar> Cancel' : 'q!']])
    end,
  })
  set_keymap("n", "dd", "dd") -- workaround waiting dd after GinPatch
  set_keymap("n", "<Plug>(C-G)<C-P>", "<Cmd>GinPatch ++opener=tabnew %<CR>")
  local graph = function(opts)
    opts = opts and (" " .. opts) or ""
    if vim.api.nvim_get_option_value("filetype", { buf = 0 }) ~= "gintonic-graph" then
      opts = [[ ++opener=rightbelow\ vsplit --first-parent]] .. opts
    end
    vim.cmd("GintonicGraph" .. opts)
  end
  set_keymap("n", "<Plug>(C-G)<C-L>", function()
    graph("-- %")
  end, { desc = "git graph current buffer", fav = false })
  set_keymap("n", "<Plug>(C-G)l", function()
    graph()
  end, { desc = "git graph", fav = false }) -- git log --graph ...
  set_keymap("n", "<Plug>(C-G)<C-D>", "<Cmd>GinDiff -- %<CR>", { desc = "git diff", fav = false })
  set_keymap("n", "<Plug>(C-G)d", "<Cmd>GinDiff<CR>", { desc = "git commit", fav = false })
  set_keymap("n", "<Plug>(C-G)<C-Space>", function()
    require("plugins.git.commit").exec()
  end, { desc = "git commit", fav = false })
  set_keymap("n", "<Plug>(C-G)s", "<Cmd>GinStatus<CR>", { desc = "git status", fav = false })
  add_palette("n", "git amend", ":Gin commit --amend ")
  add_palette("n", "git amend --no-edit", ":Gin ++wait commit --amend --no-edit ")
  add_palette("n", "git rebase -i", ":Gin rebase --rebase-merge -i ")
  add_palette(
    "n",
    "git rebase --onto A B C",
    ":Gin rebase --rebase-merge --onto ",
    { desc = "AにBからCまでの差分を乗せる" }
  )
  add_palette("n", "git push", ":Gin ++wait push origin HEAD ")
  add_palette("n", "git push --force", ":Gin ++wait push --force-with-lease --force-if-includes origin HEAD ")
  add_palette("n", "git diff", ":GinDiff ")
  add_palette("n", "git diff --ignore-all-space", ":GinDiff --ignore-all-space")
end

-- return
return {
  {
    "lambdalisue/gin.vim",
    dependencies = { "vim-denops/denops.vim" },
    config = setup_gin,
  },
  {
    "knsh14/vim-github-link",
    cmd = { "GetCommitLink", "GetCurrentBranchLink", "GetCurrentCommitLink" },
  },
  { "lewis6991/gitsigns.nvim", config = setup_gitsigns },
}
