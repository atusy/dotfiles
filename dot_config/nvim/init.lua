--[[ TODO

# quickfix

## Plugin

https://github.com/thinca/vim-qfreplace
https://github.com/itchyny/vim-qfedit

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
use { 'tyru/open-browser.vim',
use { 'williamboman/mason-lspconfig.nvim',
use { 'windwp/nvim-autopairs',

https://github.com/monaqa/dial.nvim
https://github.com/anuvyklack/hydra.nvim
https://github.com/tani/glance-vim
https://github.com/folke/trouble.nvim
https://github.com/folke/which-key.nvim
https://github.com/rcarriga/nvim-notify
https://github.com/numToStr/Comment.nvim
https://github.com/folke/noice.nvim
https://github.com/folke/todo-comments.nvim
https://github.com/simrat39/symbols-outline.nvim
https://github.com/kylechui/nvim-surround
https://github.com/lewis6991/impatient.nvim
https://github.com/stevearc/dressing.nvim
https://github.com/edluffy/hologram.nvim
https://github.com/phelipetls/jsonpath.nvim
https://github.com/delphinus/ddc-treesitter
https://github.com/Afourcat/treesitter-terraform-doc.nvim
--]]

--[[ tricks ]]
-- TODO: set up diagnostics based on https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#sumneko_lua
local vim = vim -- minimize LSP warning

-- [[ helpers ]]
local utils = require('utils').require('utils') -- force reloading self
local set_keymap = utils.set_keymap

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
set_keymap('v', 'q', function() vim.notify('v_q is disabled', vim.log.levels.ERROR) end)
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
set_keymap('n', 's', '<Nop>') -- be prefix for sandwich
set_keymap('n', '<C-G>', '<C-G><Plug>(C-G)', { noremap = true, nowait = true })
set_keymap('n', '<Plug>(C-G)<C-G>', '<Cmd>let @+ = fnamemodify(expand("%"), ":~:.")<CR>')
set_keymap('n', '<Plug>(C-G)g', '<Cmd>let @+ = expand("%:p")<CR>')
set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
set_keymap({ 'n', 'v' }, 'x', '"_x')
set_keymap({ 'n', 'v' }, 'X', '"_X')
set_keymap('n', 'gf', 'gF')
set_keymap('n', 'gff', 'gF')
set_keymap('n', 'gfv', '<cmd>vertical wincmd F<cr>')
set_keymap('n', 'gfs', '<cmd>horizontal wincmd F<cr>')
set_keymap('n', '<Left>', '^')
set_keymap('n', '<Right>', '$')
set_keymap({ 'n', 'v' }, 'gy', '"+y')
set_keymap({ 'n', 'v' }, 'gY', '"+Y')
set_keymap('c', '<C-A>', '<Home>')
set_keymap('c', '<C-E>', '<End>')
set_keymap('t', '<C-W>', function() vim.cmd('wincmd ' .. vim.fn.getcharstr()) end)
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
  vim.api.nvim_create_autocmd(
    'InsertEnter',
    {
      callback = function() vim.api.nvim_win_set_option(0, 'cursorline', false) end,
      group = 'ToggleCursorline'
    }
  )
  vim.api.nvim_create_autocmd(
    'InsertLeave',
    {
      callback = function() vim.api.nvim_win_set_option(0, 'cursorline', true) end,
      group = 'ToggleCursorline'
    }
  )
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
    require('config.window'),
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
require 'jetpack.packer'.startup(function(use)
  local used = {}
  local function use_deps(config)
    for _, dep in pairs(config.deps) do
      dep = type(dep) == "table" and dep or { dep }
      if not used[dep[1]] then
        used[dep[1]] = true
        if dep.frozen == nil then
          dep.frozen = true
        end
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
    'delphinus/cellwidths.nvim',

    -- utils
    'numToStr/Comment.nvim',
    'nathom/filetype.nvim',
    'lambdalisue/nerdfont.vim',
    'lambdalisue/guise.vim',
    'lambdalisue/fern.vim',
    'lambdalisue/fern-renderer-nerdfont.vim',
    'segeljakt/vim-silicon', -- pacman -S silicon

    -- ui
    -- "MunifTanjim/nui.nvim",
    -- "rcarriga/nvim-notify",
    -- "folke/noice.nvim",
    -- "stevearc/stickybuf.nvim",

    -- windows and buffers
    'moll/vim-bbye',
    'm00qek/baleia.nvim',
    { 'tyru/capture.vim' },
    { 'folke/zen-mode.nvim' },

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
    'ggandor/flit.nvim',
    'yuki-yano/fuzzy-motion.vim',

    -- treesitter
    { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" },
    'nvim-treesitter/playground',
    'nvim-treesitter/nvim-treesitter-refactor',
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

-- require("noice").setup({
--   messages = {
--     enabled = false,
--   }
-- })

-- cellwidths
-- template is modified on load as builtin mechanism has difficulty to dump
require("cellwidths").setup { name = "default" }
vim.cmd.CellWidthsDelete("{" .. table.concat({
  0x2190, 0x2191, 0x2192, 0x2193, -- ←↑↓→
  0x2713, -- ✓
}, ", ") .. "}")

-- illuminate
local Illuminate = require 'illuminate'
Illuminate.configure({
  filetype_denylist = { 'fugitive', 'fern' },
  modes_allowlist = { 'n' }
})
set_keymap('n', '<C-H>', Illuminate.goto_prev_reference, { desc = 'previous references' })
set_keymap('n', '<C-L>', Illuminate.goto_next_reference, { desc = 'next reference' })


--[[ buffer settings ]]
set_keymap('n', '<C-P><C-P>', '<C-^>')
-- Bbye
set_keymap('n', '<C-P><C-D>', ':up | Bdelete<CR>')
set_keymap('n', '<C-P><C-W>', ':Bwipeout!<CR>')
-- asterisk
set_keymap('n', '*', '<Plug>(asterisk-z*)')
set_keymap('v', '*', '<Plug>(asterisk-gz*)')

-- baleia to parse ANSI
local baleia = require('baleia').setup()
set_keymap(
  'n', '<Plug>(parse-ansi)',
  function() baleia.once(vim.api.nvim_get_current_buf()) end,
  { desc = 'Parse ANSI escape sequences in current buffer' }
)

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

set_keymap('', '<A-f>', 'f')
set_keymap('', '<A-F>', 'F')
set_keymap('', '<A-t>', 't')
set_keymap('', '<A-T>', 'T')
set_keymap('', 'f', hopper('AFTER_CURSOR'), { desc = 'Hop after' })
set_keymap('', 'F', hopper('BEFORE_CURSOR'), { desc = 'Hop before' })
set_keymap('', 't', hopper('AFTER_CURSOR', -1), { desc = 'Hop after' })
set_keymap('', 'T', hopper('BEFORE_CURSOR', 1), { desc = 'Hop before' })

-- leap
-- LeapBackdrop highlight is defined at colorscheme.lua
local _leap = require('leap')
_leap.setup({ safe_labels = {}, })
set_keymap(
  { 'n', 'v' }, 'ss',
  function()
    _leap.leap({ target_windows = { vim.fn.win_getid() } })
  end
)
require('flit').setup {
  keys = { f = ' f', F = ' F', t = ' t', T = ' T' },
  -- A string like "nv", "nvo", "o", etc.
  labeled_modes = "v",
  multiline = true,
  -- Like `leap`s similar argument (call-specific overrides).
  -- E.g.: opts = { equivalence_classes = {} }
  opts = {}
}

-- fuzzymotion
set_keymap({ 'n', 'v' }, 'sf', function() vim.cmd("FuzzyMotion") end)

-- edgemotion
set_keymap('', '<A-]>', '<Plug>(edgemotion-j)', {})
set_keymap('', '<A-[>', '<Plug>(edgemotion-k)', {})


--[[ statusline settings ]]
-- lualine
require 'lualine'.setup {
  options = { theme = 'moonfly', component_separators = '', },
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
    lualine_y = { 'branch', 'diff' },
    lualine_z = { 'tabs' },
  },
  extensions = { 'fern', 'toggleterm' }
}

--[[ filer settings ]]
-- fern
-- TODO: using nvim api currently fails to show file list
vim.g["fern#renderer"] = "nerdfont"
vim.g["fern#renderer#nerdfont#indent_markers"] = 1
vim.g["fern#window_selector_use_popup"] = 1
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
  set_keymap('n', '<C-F>', '<C-W>p', { buffer = 0 })
  set_keymap('n', 'm', '<Nop>', { buffer = 0, remap = true })
  set_keymap('n', '<Plug>(fern-action-open:chowcho)', fern_chowcho, { buffer = 0 })
  -- set_keymap('n', 's', '<Plug>(fern-action-open:chowcho)', { buffer = 0, nowait = true, remap = true })
end

vim.api.nvim_create_autocmd("FileType",
  {
    pattern = "fern",
    group = vim.api.nvim_create_augroup("fern-custom", {}),
    callback = function() pcall(init_fern) end
  }
)


--[[ treesitter settings ]]
local parser_install_dir = vim.fn.stdpath('data') .. "/treesitter"
vim.opt.runtimepath:append(parser_install_dir)
require 'nvim-treesitter.configs'.setup {
  parser_install_dir = parser_install_dir,
  ensure_installed = {
    'bash', 'bibtex', 'c', 'c_sharp', 'cmake', 'cpp', 'css', 'dockerfile',
    'dot', 'go', 'gomod', 'gowork', 'graphql', 'haskell', 'hcl', 'help', 'html',
    'http', 'java', 'javascript', 'json', 'json5', 'julia', 'latex', 'lua',
    'make', 'markdown', 'markdown_inline', 'ninja', 'nix', 'python', 'r', 'regex', 'rst', 'ruby', 'rust',
    'scss', 'teal', 'toml', 'tsx', 'typescript', 'vala', 'vim', 'vue', 'yaml'
  },
  context_commentstring = { enable = true, enable_autocmd = false },
  highlight = {
    enable = true,
    disable = function(lang)
      local ok = pcall(function() vim.treesitter.get_query(lang, 'highlights') end)
      return not ok
    end,
  },
  indent = { enable = true },
  yati = { enable = true },
}
require('Comment').setup {
  toggler = { line = 'gcc', block = 'gcb' },
  pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
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
    css = { 'media_statement', 'rule_set', },
    scss = { 'media_statement', 'rule_set', },
    rmd = { 'section' }
  },
})
set_keymap(
  'n', '<Leader>rn', -- lsp may overridde the feature if renameProvider is available
  function() require 'nvim-treesitter-refactor.smart_rename'.smart_rename(0) end,
  { desc = 'treesitter rename' }
)
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
set_keymap('n', '<Leader>j', ':ToggleTermSendCurrentLine<CR>j',
  { desc = 'send the line to toggle term and go to next line' })
set_keymap('v', '<Leader>j', ":ToggleTermSendVisualSelection<CR>gv<Esc>",
  { desc = 'send the selection to toggle term while keeping the cursor position' })

vim.opt.runtimepath:append("/home/atusy/ghq/github.com/atusy/telescomp")
local cmdline = utils.require('telescomp.cmdline')
local cmdline_builtin = utils.require('telescomp.cmdline.builtin')
set_keymap('c', '<C-X><C-R>', cmdline_builtin.git_ref)
set_keymap('c', '<C-X><C-F>', cmdline_builtin.find_files)
set_keymap('c', '<C-X><C-M>', cmdline_builtin.menu)
set_keymap('c', '<C-X><C-N>', cmdline_builtin.cmdline)
set_keymap('c', '<C-X><C-S>', cmdline_builtin.lsp_document_symbols)
set_keymap('c', '<C-X><C-H>', cmdline_builtin.git_status)
set_keymap('c', '<C-X><C-X>', function()
  local opt = cmdline.spec_completer_options({ expand = true })
  local default_text = opt.default_text
  if string.match(default_text, '^%./') ~= nil then
    opt.default_text = string.gsub(default_text, '^%./', '')
    return cmdline_builtin.find_files({}, opt)
  end
  if string.match(default_text, '/') ~= nil then
    return cmdline_builtin.find_files({}, opt)
  end

  return cmdline_builtin.cmdline({}, opt)
end)
