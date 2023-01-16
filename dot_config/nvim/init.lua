--[[ TODO
https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
https://github.com/sumneko/lua-language-server/wiki/Annotations
https://qiita.com/delphinus/items/fb905e452b2de72f1a0f
https://zenn.dev/nnsnico/articles/customize-lsp-handler
https://dev.classmethod.jp/articles/eetann-change-neovim-lsp-diagnostics-format/

## Plugin

"rlch/github-notifications.nvim",
use { 'LeafCage/vimhelpgenerator' }
use { 'kevinhwang91/nvim-bqf', ft = 'qf' }
use { 'mattn/emmet-vim',
use { 'pwntester/octo.nvim',
use { 'shinespark/vim-list2tree' }
use { 'skanehira/denops-docker.vim' }
use { 'skanehira/denops-graphql.vim',
use { 'skanehira/denops-silicon.vim',
use { 'skanehira/denops-translate.vim',
use { 'thinca/vim-quickrun',
use { 'thinca/vim-themis' }
use { 'tyru/open-browser-github.vim' }
use { 'windwp/nvim-autopairs',

https://github.com/monaqa/dial.nvim
https://github.com/anuvyklack/hydra.nvim
https://github.com/tani/glance-vim
https://github.com/folke/trouble.nvim
https://github.com/folke/which-key.nvim
https://github.com/rcarriga/nvim-notify
https://github.com/folke/noice.nvim
https://github.com/folke/todo-comments.nvim
https://github.com/simrat39/symbols-outline.nvim
https://github.com/kylechui/nvim-surround
https://github.com/edluffy/hologram.nvim
https://github.com/delphinus/ddc-treesitter
https://github.com/Afourcat/treesitter-terraform-doc.nvim
https://github.com/nullchilly/fsread.nvim
https://github.com/joechrisellis/lsp-format-modifications.nvim

https://github.com/monaqa/tree-sitter-unifieddiff
https://github.com/thinca/modesearch.vim
https://github.com/thinca/vim-partedit
https://github.com/uga-rosa/ccc.nvim
https://github.com/matsui54/ddc-buffer
https://github.com/David-Kunz/markid
https://github.com/stevearc/dressing.nvim
https://github.com/hrsh7th/nvim-gtd
https://github.com/hrsh7th/vim-searchx
https://github.com/b0o/SchemaStore.nvim
--]]

-- [[ helpers ]]
local utils = require('utils').require('utils') -- force reloading self
utils.setup()
local set_keymap = utils.set_keymap

--[[ options ]]
vim.opt.exrc = true
vim.opt.updatetime = 250

-- statuscolumn
vim.opt.signcolumn = 'yes'
vim.opt.foldcolumn = 'auto'
vim.opt.statuscolumn = "%=%{&rnu ? v:relnum ? v:relnum : v:lnum : &nu ? v:lnum : ''}%s%C"

-- window
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.breakindent = true

-- buffer
vim.opt.autoread = true
vim.opt.matchtime = 1
vim.opt.mouse = 'a'
vim.opt.pumblend = 30
vim.opt.winblend = 30
vim.opt.pumheight = 10
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸▹┊",
  trail = "▫",
  extends = "»",
  precedes = "«",
}
vim.opt.cursorline = true
vim.opt.guicursor = {
  [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
  [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
  [[sm:block-blinkwait175-blinkoff150-blinkon175]],
}

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.incsearch = true

-- tab and indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- others
if vim.fn.executable('zsh') == 1 then
  vim.opt.shell = 'zsh'
end
if vim.fn.executable('rg') == 1 then
  vim.opt.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
  vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
end

-- skipped builtins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_fzf = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

--[[ commands ]]
vim.api.nvim_create_user_command('W', 'write !sudo tee % >/dev/null', {})
vim.api.nvim_create_user_command('Normal', function(opts)
  local code = vim.api.nvim_replace_termcodes(opts.args, true, true, true)
  local normal = opts.bang and 'normal!' or 'normal'
  for i = opts.line1, opts.line2 do
    vim.cmd(i .. normal .. ' ' .. code)
  end
end, { nargs = 1, range = true, bang = true })

--[[ mappings ]]
vim.g.mapleader = ' '
set_keymap('v', 'q', '<Nop>')
set_keymap(
  'n',
  'q',
  function()
    local reg = vim.fn.reg_recording()
    if reg ~= '' then return 'q<cmd>echo "stop recording @' .. reg .. '"<cr>' end
    local char = vim.fn.getcharstr(0)
    if char == 'q' or not char:match('[a-z]') then return 'q' .. char end
    vim.notify('q[a-z] are disabled except qq', vim.log.levels.ERROR)
  end,
  {
    expr = true,
    nowait = true,
    desc = 'Start/stop recording macro, but disable a-z except q'
  }
)
set_keymap({ 'n', 'v' }, 's', '<Nop>') -- be prefix for sandwich and fuzzy finders
set_keymap('n', '<C-G>', '<C-G><Plug>(C-G)', { noremap = true })
set_keymap('n', '<Plug>(C-G)<C-G>', '<Cmd>let @+ = fnamemodify(expand("%"), ":~:.")<CR>')
set_keymap('n', '<Plug>(C-G)g', '<Cmd>let @+ = expand("%:p")<CR>')
set_keymap('n', 'gf', 'gF')
set_keymap('n', 'gff', 'gF')
set_keymap('n', 'gfh', '<cmd>leftabove vertical wincmd F<cr>')
set_keymap('n', 'gfj', '<cmd>below horizontal wincmd F<cr>')
set_keymap('n', 'gfk', '<cmd>above horizontal wincmd F<cr>')
set_keymap('n', 'gfl', '<cmd>rightbelow vertical wincmd F<cr>')
set_keymap('c', '<C-A>', '<Home>')
set_keymap('t', '<C-W>', [[<C-\><C-N><C-W>]])
set_keymap({ '', '!', 't' }, [[<C-\>]], [[<C-\><C-N>]], { nowait = true })
set_keymap('x', 'zf', [[mode() == 'V' ? 'zf' : 'Vzf']], { expr = true })
set_keymap('x', '/', '<Esc>/\\%V', { desc = 'start search within selection' })

-- mappings: register
set_keymap({ 'n', 'v' }, 'x', '"_x')
set_keymap({ 'n', 'v' }, 'X', '"_X')
set_keymap({ 'n', 'v' }, 'gy', '"+y')
set_keymap({ 'n', 'v' }, 'gY', '"+Y')

-- mappings: textobj
set_keymap({ 'o', 'x' }, 'ii', '2i') -- e.g., vii' to select 'foo' including quotes but outer spaces
set_keymap({ 'o', 'x' }, 'il', ':<c-u>normal! $v^<cr>')
set_keymap({ 'o', 'x' }, 'al', ':<c-u>normal! $v0<cr>')
set_keymap({ 'o', 'x' }, 'ie', ':<c-u>normal! gg0vG$<cr>')

-- mappings: mouse
set_keymap('n', '<LeftDrag>', '<Nop>')
set_keymap('n', '<LeftRelease>', '<Nop>')
set_keymap(
  'n', '<Plug>(toggle-left-drag)',
  function()
    for _, m in pairs(vim.api.nvim_get_keymap('n')) do
      if m.lhs == '<LeftDrag>' then
        if m.rhs == '' then
          vim.keymap.del('n', '<LeftDrag>')
          vim.keymap.del('n', '<LeftRelease>')
        end
        return
      end
    end
    set_keymap('n', '<LeftDrag>', '<Nop>')
    set_keymap('n', '<LeftRelease>', '<Nop>')
  end,
  { desc = 'toggle left drag' }
)
pcall(
  vim.api.nvim_exec,
  [[
    nnoremenu PopUp.Toggle\ Drag <Plug>(toggle-left-drag)
    aunmenu PopUp.How-to\ disable\ mouse
  ]],
  false
)

-- mappings: jumplist
local function jump(forward)
  local buf_cur = vim.api.nvim_get_current_buf()
  local jumplist = vim.fn.getjumplist()
  local jumps = jumplist[1]
  local idx_cur = jumplist[2] + 1
  local function is_target(buf) return buf ~= buf_cur and vim.api.nvim_buf_is_loaded(buf) end

  if forward then
    for i = 1, #jumps - idx_cur do
      if is_target(jumps[idx_cur + i].bufnr) then return i .. '<C-I>' end
    end
  else
    for i = 1, idx_cur - 1 do
      if is_target(jumps[idx_cur - i].bufnr) then return i .. '<C-O>' end
    end
  end
end

set_keymap('n', 'g<C-O>', function() jump(false) end, { fav = false, expr = true })
set_keymap('n', 'g<C-I>', function() jump(true) end, { fav = false, expr = true })

-- mappings: save and ...
set_keymap(
  'n',
  '<Plug>(save)',
  function() vim.cmd(vim.fn.filereadable('%') and 'up' or 'write') end,
  { fav = false }
)
set_keymap({ 'i', 'n' }, '<C-S>', [[<C-\><C-N><Plug>(save)<Plug>(C-S)]], { fav = false }) -- Save
set_keymap('n', '<Plug>(C-S)<C-A>', ':wa<CR>', { fav = false }) -- Save All
set_keymap('n', '<Plug>(C-S)<C-O>', jump, { fav = false, expr = true }) -- Save and jump to previous buf
set_keymap('n', '<Plug>(C-S)<C-E>', ':e #<CR>', { fav = false }) -- Save and Edit alt
set_keymap('n', '<Plug>(C-S)<C-Q>', ':q<CR>', { fav = false }) -- Save and Quit
set_keymap('n', '<Plug>(C-S)<C-V>', function()
  vim.cmd("!chezmoi apply")
  vim.cmd("source $MYVIMRC")
end, { fav = false })
set_keymap(-- Save and Source
  'n', '<Plug>(C-S)<C-M>',
  function()
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    local bufext = bufname:gsub('.*%.', '')
    if bufext ~= 'vim' and bufext ~= 'lua' then
      vim.notify('Cannot source: ' .. bufname, vim.log.levels.ERROR)
      return
    end
    return ':source %'
  end,
  { expr = true, fav = false }
)

-- mappings: window
local function move_float_win(row, col)
  local conf = vim.api.nvim_win_get_config(0)
  if conf.relative == '' then return false end
  for k, v in pairs({ row = row, col = col }) do
    if type(conf[k]) == 'table' then
      conf[k][false] = conf[k][false] + v
    else
      conf[k] = conf[k] + v
    end
  end
  vim.api.nvim_win_set_config(0, conf)
  return true
end

local function win_move_or_cmd(row, col, cmd)
  if not move_float_win(row, col) then
    vim.cmd("wincmd " .. cmd)
  end
end

set_keymap({ '', 't' }, '<C-Up>', function() win_move_or_cmd(-1, 0, '2+') end)
set_keymap({ '', 't' }, '<C-Down>', function() win_move_or_cmd(1, 0, '2-') end)
set_keymap({ '', 't' }, '<C-Right>', function() win_move_or_cmd(0, 2, '2>') end)
set_keymap({ '', 't' }, '<C-Left>', function() win_move_or_cmd(0, -2, '2<') end)

-- mappings: <Plug> to be invoked by Telescope keymap
set_keymap(
  'n', '<Plug>(clipboard-cwd)', '<Cmd>let @+=getcwd()<CR>', { desc = 'clipboard cwd' }
)
set_keymap(
  'n', '<Plug>(clipboard-buf)', '<Cmd>let @+=expand("%:p")<CR>', { desc = 'clipboard full file path of buf' }
)
set_keymap(
  'n', '<Plug>(clipboard-dir)', '<Cmd>let @+=expand("%:p:h")<CR>', { desc = 'clipboard full dirname path of buf' }
)

--[[ autocmd ]]
vim.api.nvim_create_autocmd(
  'TermOpen', { pattern = '*', group = utils.augroup, command = 'startinsert' }
)

vim.api.nvim_create_autocmd('InsertEnter', {
  desc = 'Toggle cursorline on InsertEnter/Leave iff cursorline is set on normal mode',
  group = utils.augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local wo = vim.wo[win]
    if not wo.cursorline then return end
    wo.cursorline = false
    vim.api.nvim_create_autocmd('ModeChanged', {
      -- InsertLeave is not adequate because <C-C> won't trigger it
      desc = 'Restore cursorline when leaveing insert mode.',
      pattern = 'i:*', group = utils.augroup, once = true,
      callback = function()
        pcall(vim.api.nvim_win_set_option, win, 'cursorline', true)
      end,
    })
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank() end,
  group = utils.augroup,
})

vim.api.nvim_create_autocmd(
  'FileType',
  {
    desc = 'Interactively view quickfix lines',
    pattern = 'qf',
    group = utils.augroup,
    callback = function(_)
      set_keymap('n', 'j', 'j<CR>zz<C-W>p', { buffer = 0 })
      set_keymap('n', 'k', 'k<CR>zz<C-W>p', { buffer = 0 })
    end
  }
)

--[[ Terminal ]]
-- nvim-remote for edit-commandline zle
if vim.fn.executable('nvr') == 1 then
  vim.env.EDITOR_CMD = [[nvr -cc "above 5split" --remote-wait-silent +"setlocal bufhidden=wipe filetype=zsh.nvr-zsh"]]
  vim.api.nvim_create_autocmd(
    'FileType',
    {
      desc = 'Go back to the terminal window on WinClosed. Otherwise, the current window to leftest above',
      group = utils.augroup,
      pattern = { 'zsh.nvr-zsh' },
      callback = function(args)
        vim.schedule(function()
          local parent = vim.fn.win_getid(vim.fn.winnr('#'))
          -- local local_group = vim.api.nvim_create_augroup(args.file, {})
          vim.api.nvim_create_autocmd('WinClosed', {
            -- group = local_group,
            buffer = args.buf,
            once = true,
            callback = function()
              vim.schedule(function()
                local ok = pcall(vim.api.nvim_set_current_win, parent)
                if ok then vim.cmd.startinsert() end
              end)
            end
          })
        end)
      end,
      nested = true,
    }
  )
end

--[[ lazy.nvim ]]
local DATAPATH = vim.fn.stdpath("data")
local lazypath = DATAPATH .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)
require('lazy').setup("plugins", {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

if vim.v.vim_did_enter == 1 then
  if vim.g['sandwich#default_recipes'] == nil then
    require('lazy').load({ plugins = 'vim-sandwich' })
  end
  local function try(...)
    local ok, res = pcall(...)
    if not ok then vim.notify(res, vim.log.levels.ERROR) end
    return ok
  end

  local loaded = vim.tbl_keys(package.loaded)
  for _, p in pairs(loaded) do
    if p == 'atusy' or vim.startswith(p, 'atusy.') then
      utils.require(p)
    end
  end

  local configurable
  for _, p in pairs(loaded) do
    if p == 'plugins' or vim.startswith(p, 'plugins.') then
      for _, d in pairs(utils.require(p)) do
        if type(d) == "table" and d.enabled ~= false then
          if d.init then
            configurable = try(d.init)
            if not configurable then
              vim.notify('FAILED: ' .. d .. '.init()', vim.log.levels.ERROR)
            end
          end
          if d.config and configurable then
            if not try(d.config) then
              vim.notify('FAILED: ' .. d .. '.config()', vim.log.levels.ERROR)
            end
          end
        end
      end
    end
  end
end
