--[[
TODO

# quickfix

## Plugin

https://github.com/thinca/vim-qfreplace
https://github.com/itchyny/vim-qfedit

use { 'LeafCage/vimhelpgenerator' }
use { 'kevinhwang91/nvim-bqf', ft = 'qf' }
use { 'mattn/emmet-vim',
use { 'pwntester/octo.nvim',
use { 'ray-x/lsp_signature.nvim',
use { 'shinespark/vim-list2tree' }
use { 'skanehira/denops-docker.vim' }
use { 'skanehira/denops-graphql.vim',
use { 'skanehira/denops-silicon.vim',
use { 'skanehira/denops-translate.vim',
use { 'thinca/vim-quickrun',
use { 'thinca/vim-themis' }
use { 'tyru/open-browser-github.vim' }
use { 'tyru/open-browser.vim',
use { 'williamboman/mason-lspconfig.nvim',
use { 'windwp/nvim-autopairs',

--]]

--[[ tricks ]]
-- TODO: set up diagnostics based on https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#sumneko_lua
local vim = vim -- minimize LSP warning

-- [[ helpers ]]
local utils = require('utils')
utils.require('utils')
local set_keymap = utils.set_keymap
function Inspect(...)
  print(vim.inspect(...))
end

local function safely(f)
  return function(...) pcall(f, ...) end
end

--[[ options ]]
-- signcolumn
vim.opt.signcolumn = 'yes'
vim.opt.relativenumber = true
vim.opt.number = true

-- window
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.backspace = { 'indent', 'eol', 'start' }

-- buffer
vim.opt.autoread = true
vim.opt.matchtime = 1
vim.opt.mouse = 'a'
vim.opt.pumheight = 10
vim.opt.termguicolors = true
vim.opt.updatetime = 300 -- recommended by vgit
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸▹┊",
  trail = "▫",
  extends = "❯",
  precedes = "❮",
}
vim.opt.cursorline = true
vim.opt.guicursor = {
  [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
  [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
  [[sm:block-blinkwait175-blinkoff150-blinkon175]],
}

-- search
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.incsearch = true -- false reccomended by vgit

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


--[[ mappings ]]
vim.g.mapleader = ' '
for _, k in ipairs({ 's', ',', ';' }) do
  set_keymap('n', '<A-' .. k .. '>', k)
end
set_keymap('n', 's', '<Nop>') -- be prefix for sandwich
set_keymap('n', 'qa', '<Nop>') -- avoid typo of :qa
set_keymap('n', ';', ':')
set_keymap('n', '<C-G><C-G>', '<C-G><Cmd>let @+ = expand("%")<CR>')
set_keymap('', '-', '"_') -- shortcut to blackhole register
set_keymap('', '+', '"+') -- shortcut to clipboard+ register
set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
set_keymap('n', 'x', '"_x')
set_keymap('n', 'X', '"_X')
set_keymap('n', 'gf', 'gF')
set_keymap('n', '<Left>', '^')
set_keymap('n', '<Right>', '$')
set_keymap({ 'n', 'v' }, 'gy', '"+y')
set_keymap({ 'n', 'v' }, 'gY', '"+Y')
set_keymap('c', '<C-A>', '<Home>')
set_keymap('c', '<C-E>', '<End>')
set_keymap('t', '<C-W>', "'<Cmd>wincmd ' .. getcharstr() .. '<CR>'", { expr = true })
set_keymap({ '', 't' }, '<C-Up>', '<Cmd>2wincmd +<CR>')
set_keymap({ '', 't' }, '<C-Down>', '<Cmd>2wincmd -<CR>')
set_keymap({ '', 't' }, '<C-Left>', '<Cmd>2wincmd <<CR>')
set_keymap({ '', 't' }, '<C-Right>', '<Cmd>2wincmd ><CR>')


--[[ personal utilities ]]
-- Apply MYVIMRC
vim.api.nvim_create_user_command(
  'ApplyMYVIMRC',
  function()
    vim.cmd('up')
    vim.cmd('!chezmoi apply')
    vim.cmd('source $MYVIMRC')
  end,
  {}
)

vim.api.nvim_create_augroup('ToggleCursorline', {})
if vim.opt.cursorline:get() then
  for _, events in ipairs({
    {'InsertEnter', 'InsertLeave'},
    {'WinLeave', 'WinEnter'},
  }) do
    vim.api.nvim_create_autocmd(
      events[1], {
        callback = function()
          vim.wo.cursorline = false
        end
      }
    )
    vim.api.nvim_create_autocmd(
      events[2], {
        callback = function()
          vim.wo.cursorline = true
        end
      }
    )
  end
end

-- nvim-remote for edit-commandline zle
-- <Space>bd will update, wipe buffer, and go back to the caller terminal
if vim.fn.executable('nvr') == 1 then
  vim.env.EDITOR_CMD = 'nvr -cc "below 5split" --remote-wait-silent +"set bufhidden=wipe"'
end

--[[ PLUGIN SETTINGS ]]

local configurations = (function()
  -- temporary redefine require to enable definition jumps
  local require = utils.require
  return {
    -- order may matter
    require('config.colorscheme'),
    require('config.git'),
    require('config.lsp'),
    require('config.telescope'),
    require('config.ddc'),
  }
end)()
local jetpackfile = vim.fn.stdpath('data') .. '/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim'
if vim.fn.filereadable(jetpackfile) == 0 then
  vim.fn.system(string.format(
    'curl -fsSLo %s --create-dirs %s',
    jetpackfile,
    "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"
  ))
end
vim.cmd('packadd vim-jetpack')
require 'jetpack'.startup(function(use)
  local used = {}
  local function use_deps(config)
    for _, dep in pairs(config.deps) do
      dep = type(dep) == "table" and dep or { dep }
      if not used[dep[1]] then
        used[dep[1]] = true
        dep.frozen = dep.frozen ~= nil and dep.frozen or true
        use(dep)
      end
    end
  end

  for _, config in ipairs(configurations) do
    use_deps(config)
  end
  use_deps({ deps = {
    { 'tani/vim-jetpack', opt = 1 }, -- bootstrap

    -- basic dependencies
    'tpope/vim-repeat',
    'kyazdani42/nvim-web-devicons', -- for lualine
    'vim-denops/denops.vim',
    'kana/vim-submode',

    -- utils
    'tpope/vim-commentary',
    'nathom/filetype.nvim',
    'lambdalisue/guise.vim',
    'lambdalisue/fern.vim',
    'segeljakt/vim-silicon', -- pacman -S silicon

    -- windows and buffers
    'tkmpypy/chowcho.nvim',
    'moll/vim-bbye',
    { 'tyru/capture.vim' },

    -- better something
    'wsdjeg/vim-fetch', -- :e with linenumber
    'jghauser/mkdir.nvim', -- :w with mkdir
    'haya14busa/vim-asterisk', -- *
    'lambdalisue/readablefold.vim',

    -- statusline
    'nvim-lualine/lualine.nvim',
    -- use 'b0o/incline.nvim' -- TODO

    -- motion
    'haya14busa/vim-edgemotion',
    'phaazon/hop.nvim',
    'ggandor/leap.nvim',
    'ggandor/leap-ast.nvim',
    'yuki-yano/fuzzy-motion.vim',
    {'gen740/SmoothCursor.nvim'},

    -- treesitter
    { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" },
    'nvim-treesitter/playground',
    'yioneko/nvim-yati',
    'haringsrob/nvim_context_vt',
    'romgrk/nvim-treesitter-context',
    'mfussenegger/nvim-treehopper',
    'JoosepAlviste/nvim-ts-context-commentstring',

    -- text object
    'machakann/vim-sandwich',

    -- terminal
    'akinsho/toggleterm.nvim',

    -- language specific
    -- go
    'mattn/vim-goimports'
  } })
end)
for _, name in ipairs(vim.fn['jetpack#names']()) do
  if not vim.fn['jetpack#tap'](name) then
    vim.fn['jetpack#sync']()
    break
  end
end

for _, config in ipairs(configurations) do
  config.setup()
end

-- illuminate
local Illuminate = require 'illuminate'
Illuminate.configure({
  filetype_denylist = { 'fugitive', 'fern' },
  modes_allowlist = { 'n' }
})
set_keymap('n', '<C-H>', Illuminate.goto_prev_reference, { desc = 'previous references' })
set_keymap('n', '<C-L>', Illuminate.goto_next_reference, { desc = 'next reference' })


--[[ window settings ]]
-- chowcho
require 'chowcho'.setup({
  use_exclude_default = false,
  exclude = function(_, _) return false end
})
local _chowcho_run = require 'chowcho'.run
local _chowcho_bufnr = function(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.fn.bufnr('%'), vim.opt_local
  end)
end
local _chowcho_buffer = function(winid, bufnr, opt_local)
  return vim.api.nvim_win_call(winid, function()
    local old = _chowcho_bufnr(0)
    vim.cmd("buffer " .. bufnr)
    if opt_local ~= nil then
      vim.opt_local = opt_local
    end
    return old
  end)
end

local function _chowcho_focus()
  -- Focues window
  if #vim.api.nvim_tabpage_list_wins(0) > 2 then
    _chowcho_run(
      safely(vim.api.nvim_set_current_win),
      {
        use_exclude_default = false,
        exclude = function(_, win)
          local config = vim.api.nvim_win_get_config(win)
          return config.focasable == false
        end
      }
    )
  else
    vim.cmd('wincmd w')
  end
end

set_keymap({ '', 't' }, '<C-W><C-W>', _chowcho_focus)
set_keymap({ '', 't' }, '<C-W>w', _chowcho_focus)

local function _chowcho_hide()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local nwins = #wins
  if nwins == 1 then
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabclose")
    end
    return
  end
  if nwins == 2 then
    local curwin = vim.api.nvim_get_current_win()
    for _, w in ipairs(wins) do
      if w ~= curwin then
        vim.api.nvim_win_hide(w)
        return
      end
    end
  end
  if nwins > 2 then
    _chowcho_run(safely(vim.api.nvim_win_hide))
  end
end

set_keymap({ '', 't' }, '<C-W>c', _chowcho_hide)
set_keymap({ '', 't' }, '<C-W><C-Space>', _chowcho_hide)
set_keymap({ '', 't' }, '<C-W><Space>', _chowcho_hide)

local function _chowcho_edit()
  -- Edits buffer from the selected in the current
  if #vim.api.nvim_tabpage_list_wins(0) < 1 then return end
  _chowcho_run(
    safely(function(n)
      local bufnr, opt_local = _chowcho_bufnr(n)
      _chowcho_buffer(0, bufnr, opt_local)
    end),
    {
      use_exclude_default = false,
      exclude = function(buf, _)
        return vim.api.nvim_buf_call(buf, function()
          return vim.api.nvim_buf_get_option(0, "modifiable") == false
        end)
      end
    }
  )
end

set_keymap({ '', 't' }, '<C-W>e', _chowcho_edit)
set_keymap({ '', 't' }, '<C-W><C-E>', _chowcho_edit)

local function _chowcho_exchange()
  -- Swaps buffers between windows
  if #vim.api.nvim_tabpage_list_wins(0) <= 2 then
    vim.cmd("wincmd x")
    return
  end
  _chowcho_run(
    safely(function(n)
      if n == vim.api.nvim_get_current_win() then
        return
      end
      local bufnr0, opt_local0 = _chowcho_bufnr(0)
      local bufnrn, opt_localn = _chowcho_buffer(n, bufnr0, opt_local0)
      _chowcho_buffer(0, bufnrn, opt_localn)
    end),
    {
      use_exclude_default = false,
      exclude = function(_, win)
        local winconf = vim.api.nvim_win_get_config(win)
        return winconf.external or winconf.relative ~= ""
      end
    }
  )
end

set_keymap({ '', 't' }, '<C-W><C-X>', _chowcho_exchange)
set_keymap({ '', 't' }, '<C-W>x', _chowcho_exchange)


--[[ buffer settings ]]
set_keymap('n', '<C-P><C-P>', '<C-^>')
-- Bbye
set_keymap('n', '<C-P><C-D>', ':up | Bdelete<CR>')
set_keymap('n', '<C-P><C-W>', ':Bwipeout!<CR>')
-- asterisk
set_keymap('n', '*', '<Plug>(asterisk-z*)')
set_keymap('v', '*', '<Plug>(asterisk-gz*)')

-- quickfix
vim.api.nvim_create_augroup("quickfix-custom", {})
vim.api.nvim_create_autocmd(
  'FileType',
  {
    desc = 'Interactively view quickfix lines',
    pattern = 'qf',
    group = 'quickfix-custom',
    callback = function(_)
      set_keymap('n', 'j', 'j<CR>zz<C-W>p', { buffer = 0 })
      set_keymap('n', 'k', 'k<CR>zz<C-W>p', { buffer = 0 })
    end
  }
)

--[[ textobj settings ]]
-- sandwich
vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])


--[[ motion settings ]]
-- hop
local Hop = require 'hop'
Hop.setup()
local function hopper(direction, offset)
  local hint_char1 = Hop.hint_char1
  local opt = {
    direction = require 'hop.hint'.HintDirection[direction],
    current_line_only = true,
    hint_offset = offset == nil and 0 or offset,
  }
  return function() hint_char1(opt) end
end

set_keymap('', '<Leader>f', 'f')
set_keymap('', '<Leader>F', 'F')
set_keymap('', '<leader>t', 't')
set_keymap('', '<Leader>T', 'T')
set_keymap('', 'f', hopper('AFTER_CURSOR'), { desc = 'Hop after' })
set_keymap('', 'F', hopper('BEFORE_CURSOR'), { desc = 'Hop before' })
set_keymap('', 't', hopper('AFTER_CURSOR', -1), { desc = 'Hop after' })
set_keymap('', 'T', hopper('BEFORE_CURSOR', 1), { desc = 'Hop before' })

-- leap
require('leap').setup({ safe_labels = {}, })

-- fuzzymotion
set_keymap({ 'n', 'v' }, 'ss', function() vim.cmd("FuzzyMotion") end)

-- edgemotion
set_keymap('', '<A-]>', '<Plug>(edgemotion-j)', {})
set_keymap('', '<A-[>', '<Plug>(edgemotion-k)', {})


--[[ statusline settings ]]
-- lualine
require 'lualine'.setup {
  options = { theme = 'nord', component_separators = '' },
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { 'filetype', icon_only = true }, { 'filename', path = 1 } },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { 'filetype', icon_only = true }, { 'filename', path = 1 } },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {
    lualine_a = { 'mode' },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = { 'diagnostics', 'branch', 'diff' },
    lualine_z = { 'tabs' },
  },
  extensions = { 'fern', 'toggleterm' }
}

--[[ filer settings ]]
-- fern
-- TODO: using nvim api currently fails to show file list
set_keymap('n', '<C-F>', ':Fern . -drawer -reveal=%<CR>')
local function fern_chowcho()
  local node = vim.api.nvim_exec([[
    let helper = fern#helper#new()
    echo helper.sync.get_selected_nodes()[0]["_path"]
  ]], true)
  require 'chowcho'.run(function(n)
    vim.api.nvim_set_current_win(n)
    vim.cmd("edit " .. node)
  end)
end

local function init_fern()
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.cursorline = true
  vim.opt_local.signcolumn = "auto"
  set_keymap('n', '<C-F>', '<C-W>p', {buffer = 0})
  set_keymap('n', 'm', '<Nop>', {buffer = 0, remap = true})
  set_keymap('n', '<Plug>(fern-action-open:chowcho)', fern_chowcho, {buffer = 0})
  set_keymap('n', 's', '<Plug>(fern-action-open:chowcho)', {buffer = 0, nowait = true, remap = true})
end

vim.api.nvim_create_autocmd("FileType",
  {
    pattern = "fern",
    group = vim.api.nvim_create_augroup("fern-custom", {}),
    callback = function() pcall(init_fern) end
  }
)


--[[ treesitter settings ]]
require 'nvim-treesitter.configs'.setup {
  ensure_installed = {
    'bash', 'bibtex', 'c', 'c_sharp', 'cmake', 'cpp', 'css', 'dockerfile',
    'dot', 'go', 'gomod', 'gowork', 'graphql', 'haskell', 'hcl', 'help', 'html',
    'http', 'java', 'javascript', 'json', 'json5', 'julia', 'latex', 'lua',
    'make', 'markdown', 'ninja', 'nix', 'python', 'r', 'regex', 'ruby', 'rust',
    'scss', 'teal', 'toml', 'tsx', 'typescript', 'vala', 'vim', 'vue', 'yaml'
  },
  context_commentstring = { enable = true },
  highlight = { enable = true },
  indent = { enable = true },
  yati = { enable = true },
}
local ft_to_parser = require 'nvim-treesitter.parsers'.filetype_to_parsername
ft_to_parser.zsh = 'bash'
ft_to_parser.tf = 'hcl'
require 'nvim_context_vt'.setup {
  enabled = true,
  disable_virtual_lines = true,
}
require 'treesitter-context'.setup({
  patterns = {
    css = {
      'media_statement',
      'rule_set',
    },
    scss = {
      'media_statement',
      'rule_set',
    },
  },
})
-- set_keymap('o', 'm', ':<C-U>lua require"tsht".nodes()<CR>', {silent = true})
-- set_keymap('v', 'm', ':lua require"tsht".nodes()<CR>', {silent = true})
set_keymap({ 'v', 'o' }, 'm', require 'leap-ast'.leap, { silent = true })
set_keymap('n', 'zf', function()
  vim.cmd("normal! v")
  require 'leap-ast'.leap()
  vim.cmd("normal! zf")
end, { silent = true, desc = 'manually fold lines based on treehopper' })

--[[ terminal settings ]]
vim.api.nvim_create_augroup('termopen', {})
vim.api.nvim_create_autocmd(
  'TermOpen', { pattern = '*', group = 'termopen', command = 'startinsert' }
)

-- toggleterm:general
require 'toggleterm'.setup {
  open_mapping = '<C-T>',
  insert_mappings = false,
}
local function _toggleterm_run()
  local win = vim.api.nvim_get_current_win()
  vim.cmd('ToggleTermSendCurrentLine')
  vim.api.nvim_set_current_win(win)
end

set_keymap('n', '<Leader>j', _toggleterm_run, { desc = 'ToggleTermSendCurrentLine' })

-- toggleterm:lazygit
local lazygit = require 'toggleterm.terminal'.Terminal:new {
  cmd = 'lazygit',
  hidden = true,
  direction = 'float'
}
set_keymap(
  'n', '<C-G>l',
  function() lazygit:toggle() end,
  { desc = 'lazygit', silent = true }
)
