--[[ tricks ]]
-- TODO: set up diagnostics based on https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#sumneko_lua
local vim = vim -- minimize LSP warning


--[[ options ]]
-- signcolumn
vim.opt.signcolumn = 'yes'
vim.opt.relativenumber = true
vim.opt.number = true

-- window
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.backspace = {'indent', 'eol', 'start'}

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
-- vim.opt.guicursor = {
--   [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
--   [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
--   [[sm:block-blinkwait175-blinkoff150-blinkon175]],
-- }

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
vim.opt.shell = 'zsh'
if vim.fn.executable('rg') == 1 then
  vim.opt.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
  vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
end


--[[ mappings ]]
local function set_keymap(lhs, rhs, cmd, opts)
  opts = opts or {}
  opts.desc = nil  -- desc breaks Fern actions
  vim.keymap.set(lhs, rhs, cmd, opts)
end
vim.g.mapleader = ' '
set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
set_keymap('n', 'x', '"_x')
set_keymap('n', 'X', '"_X')
set_keymap('n', 'gf', 'gF')
set_keymap({'n', 'v'}, 'gy', '"+y')
set_keymap({'n', 'v'}, 'gY', '"+Y')
set_keymap('c', '<C-A>', '<Home>')
set_keymap('c', '<C-E>', '<End>')
set_keymap('t', '<C-W>', "'<Cmd>wincmd ' .. getcharstr() .. '<CR>'", {expr = true})


--[[ personal utilities ]]
-- Apply MYVIMRC
vim.api.nvim_create_user_command(
  'ApplyMYVIMRC',
  function()
    vim.cmd('!chezmoi apply')
    vim.cmd('source $MYVIMRC')
  end,
  {}
)

-- nvim-remote for edit-commandline zle
-- <Space>bd will update, wipe buffer, and go back to the caller terminal
if vim.fn.executable('nvr') == 1 then
  vim.env.EDITOR_CMD = 'nvr -cc "below 5split" --remote-wait-silent +"set bufhidden=wipe"'
end

--[[ PLUGIN SETTINGS ]]
vim.cmd('packadd vim-jetpack')
require'jetpack'.startup(function(use)
  use { 'tani/vim-jetpack', opt = 1 } -- bootstrap

  -- basic dependencies
  use 'tpope/vim-repeat'
  use 'kyazdani42/nvim-web-devicons' -- for lualine
  use 'nvim-lua/plenary.nvim' -- for gitsigns, vgit
  use 'tami5/sqlite.lua' -- for telescope-frecency
  use 'vim-denops/denops.vim'

  -- utils
  use 'tpope/vim-commentary'
  use 'nathom/filetype.nvim'
  use 'lambdalisue/guise.vim'
  use 'lambdalisue/fern.vim'
  use 'segeljakt/vim-silicon'  -- pacman -S silicon

  -- windows and buffers
  use 'simeji/winresizer'
  use 'tkmpypy/chowcho.nvim'
  use 'moll/vim-bbye'
  use 'AndrewRadev/bufferize.vim'

  -- better something
  use 'wsdjeg/vim-fetch'         -- :e with linenumber
  use 'jghauser/mkdir.nvim'      -- :w with mkdir
  use 'haya14busa/vim-asterisk'  -- *

  -- colorscheme
  use '4513ECHO/vim-colors-hatsunemiku'
  use 'morhetz/gruvbox'

  -- highlight
  use 'RRethy/vim-illuminate'
  use 'norcalli/nvim-colorizer.lua'

  -- statusline
  use 'nvim-lualine/lualine.nvim'
  -- use 'b0o/incline.nvim' -- TODO

  -- motion
  use 'haya14busa/vim-edgemotion'
  use 'phaazon/hop.nvim'
  use 'unblevable/quick-scope'

  -- fuzzy finder
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-frecency.nvim'
  use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}

  -- git
  use 'knsh14/vim-github-link'
  use 'lambdalisue/gin.vim'
  use 'tanvirtin/vgit.nvim'

  -- treesitter
  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-treesitter/playground'
  use 'yioneko/nvim-yati'
  use 'haringsrob/nvim_context_vt'
  use 'm-demare/hlargs.nvim'
  use 'romgrk/nvim-treesitter-context'
  use 'mfussenegger/nvim-treehopper'
  use 'David-Kunz/treesitter-unit'
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  -- text object
  use 'machakann/vim-sandwich'

  -- terminal
  use 'akinsho/toggleterm.nvim'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'glepnir/lspsaga.nvim'
  use 'williamboman/mason.nvim'
  use 'folke/lsp-colors.nvim'
  use 'tamago324/nlsp-settings.nvim'

  -- ddc
  use 'Shougo/ddc.vim'
  use 'Shougo/ddc-around'
  use 'Shougo/ddc-cmdline'
  use 'Shougo/ddc-cmdline-history'
  use 'Shougo/ddc-matcher_head'  -- 入力中の単語を補完
  use 'Shougo/ddc-nvim-lsp'  -- 入力中の単語を補完
  use 'LumaKernel/ddc-file'  -- Suggest file paths
  use 'Shougo/ddc-converter_remove_overlap' -- remove duplicates
  use 'Shougo/ddc-sorter_rank'  -- Sort suggestions
  use 'Shougo/pum.vim'  -- Show popup window
  use 'matsui54/denops-signature_help'
  use 'matsui54/denops-popup-preview.vim'

  -- language specific
  -- go
  use 'mattn/vim-goimports'
end)


--[[ colorscheme/highlight ]]
-- params
vim.g.illuminate_ftblacklist = {'fern'}
local DEFAULT_COLORSCHEME = 'hatsunemiku'
local ALTERNATIVE_COLORSCHEME = 'gruvbox'
local CMD_ILLUMINATION = 'hi illuminatedWord guibg=#383D47'

-- set colorscheme
local setup_hlargs = require'hlargs'.setup
local setup_colorizer = require'colorizer'.setup
local setup_lsp_colors = require'lsp-colors'.setup
local function set_colorscheme(nm)
  vim.cmd('colorscheme ' .. nm)
  setup_hlargs()
  setup_colorizer()
  setup_lsp_colors()
  vim.cmd(CMD_ILLUMINATION)
  vim.api.nvim_exec([[
    hi link LspReferenceText illuminatedWord
    hi link LspReferenceWrite illuminatedWord
    hi link LspReferenceRead illuminatedWord
  ]], false)
end
set_colorscheme(DEFAULT_COLORSCHEME)

-- illumination for modes other than ivV
vim.api.nvim_create_augroup('illumination-by-mode', {})
vim.api.nvim_create_autocmd(
  'ModeChanged',
  {
    pattern = '*:[ivV\x16]*',
    group = 'illumination-by-mode',
    command = 'hi clear illuminatedWord'
  }
)
vim.api.nvim_create_autocmd(
  'ModeChanged',
  {
    pattern = '[ivV\x16]*:*',
    group = 'illumination-by-mode',
    command = CMD_ILLUMINATION
  }
)

-- Update colorscheme when buffer is outside of cwd
vim.api.nvim_create_augroup('theme-by-buffer', {})
vim.api.nvim_create_autocmd(
  'BufEnter',
  {
    pattern = '*',
    group = 'theme-by-buffer',
    nested = true,
    desc = 'Change theme by the path of the current buffer.',
    callback = function(args)
      local FILE = args.file
      -- Do nothing if unneeded
      if (
        (FILE == '') or
        (vim.api.nvim_exec('echo &buftype', true) ~= '')
      ) then
        return nil
      end

      -- Determine colorscheme
      local CWD = vim.fn.getcwd()
      local COLORSCHEME = CWD == string.sub(FILE, 1, string.len(CWD))
                          and DEFAULT_COLORSCHEME
                          or ALTERNATIVE_COLORSCHEME

      -- Apply colorscheme and some highlight settings
      if COLORSCHEME ~= vim.api.nvim_exec('colorscheme', true) then
        set_colorscheme(COLORSCHEME)
      end
    end
  }
)

--[[ window settings ]]
-- chowcho
local _chowcho_run = require'chowcho'.run
local _chowcho_bufnr = function(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.fn.bufnr('%'), vim.opt_local
  end)
end
local _chowcho_buffer = function(winid, bufnr, opt_local)
  return vim.api.nvim_win_call(winid, function()
    local old = _chowcho_bufnr(0)
    vim.cmd("buffer " .. bufnr)
    vim.opt_local = opt_local
    return old
  end)
end

set_keymap({'', 't'}, '<C-W>w', function()
  if vim.fn.winnr('$') > 2 then
    _chowcho_run()
  else
    vim.cmd('wincmd w')
  end
end)

set_keymap({'', 't'}, '<C-W>c', function()
  _chowcho_run(vim.api.nvim_win_hide)
end)

set_keymap({'', 't'}, '<C-W>e', function()
  if vim.fn.winnr('$') <= 1 then return end
  _chowcho_run(function(n)
    local bufnr, opt_local = _chowcho_bufnr(n)
    _chowcho_buffer(0, bufnr, opt_local)
  end)
end)

set_keymap({'', 't'}, '<C-W>x', function()
  _chowcho_run(function(n)
    if vim.fn.winnr('$') <= 2 then
      vim.cmd("wincmd x")
      return
    end
    local bufnr0, opt_local0 = _chowcho_bufnr(0)
    local bufnrn, opt_localn = _chowcho_buffer(n, bufnr0, opt_local0)
    _chowcho_buffer(0, bufnrn, opt_localn)
  end)
end)


--[[ buffer settings ]]
-- Bbye
set_keymap('n', '<Leader>bd', ':up | Bdelete<CR>')
set_keymap('n', '<Leader>bD', ':Bdelete!<CR>')
-- asterisk
set_keymap('n', '*', '<Plug>(asterisk-z*)')
set_keymap('v', '*', '<Plug>(asterisk-gz*)')


--[[ textobj settings ]]
-- sandwich
vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])


--[[ motion settings ]]
-- quick-scope
-- TODO: improve visibility by clearing highlight from the current line
vim.g.qs_highlight_on_keys = {'f', 'F', 't', 'T'}

-- hop
local Hop = require'hop'
Hop.setup()
local function hopper(direction)
  local hint_char1 = Hop.hint_char1
  local hint_direction = require'hop.hint'.HintDirection[direction]
  return function()
    hint_char1({direction = hint_direction, current_line_only = true})
  end
end
set_keymap('', '<Leader>f', hopper('AFTER_CURSOR'), {desc = 'Hop after'})
set_keymap('', '<Leader>F', hopper('BEFORE_CURSOR'), {desc = 'Hop before'})

-- edgemotion
set_keymap('', '<Leader>]', '<Plug>(edgemotion-j)', {})
set_keymap('', '<Leader>[', '<Plug>(edgemotion-k)', {})


--[[ statusline settings ]]
-- lualine
require'lualine'.setup {
  options = {theme = 'nord', component_separators = ''},
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{'filetype', icon_only = true}, 'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{'filetype', icon_only = true}, 'filename'},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {
    lualine_a = {'mode'},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {'diagnostics', 'branch', 'diff'},
    lualine_z = {'tabs'},
  },
  extensions = {'fern', 'toggleterm'}
}

--[[ filer settings ]]
-- fern
-- TODO: using nvim api currently fails to show file list
set_keymap('n', '<C-F>', ':Fern . -drawer -reveal=%<CR>')
vim.api.nvim_exec([[
  function! s:init_fern() abort
    setlocal nornu nonu cursorline signcolumn=auto
    nnoremap <buffer> <C-F> <C-W>p
  endfunction

  augroup fern-custom
    autocmd! *
    autocmd FileType fern call s:init_fern()
  augroup END
]], false)


--[[ treesitter settings ]]
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    'bash', 'bibtex', 'c', 'c_sharp', 'cmake', 'cpp', 'css', 'dockerfile',
    'dot', 'go', 'gomod', 'gowork', 'graphql', 'haskell', 'help', 'html',
    'http', 'java', 'javascript', 'json', 'json5', 'julia', 'latex', 'lua',
    'make', 'markdown', 'ninja', 'nix', 'python', 'r', 'regex', 'ruby', 'rust',
    'scss', 'teal', 'toml', 'tsx', 'typescript', 'vala', 'vim', 'vue', 'yaml'
  },
  context_commentstring = {enable = true},
  highlight = {enable = true},
  indent = {enable = true},
  yati = {enable = true},
}
local ft_to_parser = require'nvim-treesitter.parsers'.filetype_to_parsername
ft_to_parser.zsh = 'bash'
require'nvim_context_vt'.setup {enabled = true}
require'treesitter-context'.setup({
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
set_keymap('o', 'm', ':<C-U>lua require"tsht".nodes()<CR>', {silent = true})
set_keymap('v', 'm', ':lua require"tsht".nodes()<CR>', {silent = true})
set_keymap('x', 'iu', ':lua require"treesitter-unit".select()<CR>')
set_keymap('x', 'au', ':lua require"treesitter-unit".select(true)<CR>')
set_keymap('o', 'iu', ':<C-U>lua require"treesitter-unit".select()<CR>')
set_keymap('o', 'au', ':<C-U>lua require"treesitter-unit".select(true)<CR>')


--[[ git settings ]]
-- vgit
local Vgit = require'vgit'
Vgit.setup {
  keymaps = {
    ['n <leader>gj'] = 'hunk_down',
    ['n <leader>gk'] = 'hunk_up',
    ['n <leader>gs'] = 'buffer_hunk_stage',
    ['n <leader>gr'] = 'buffer_hunk_reset',
  },
  settings = {
    live_blame = {
      enabled = false
    }
  }
}
vim.api.nvim_create_user_command('ToggleBlame', Vgit.toggle_live_blame, {})


--[[ terminal settings ]]
vim.api.nvim_create_augroup('termopen', {})
vim.api.nvim_create_autocmd(
  'TermOpen', {pattern = '*', group = 'termopen', command = 'startinsert'}
)

-- toggleterm:general
require'toggleterm'.setup {
  open_mapping = '<C-T>',
  insert_mappings = false,
}
local function _toggleterm_run()
  local winnr = vim.fn.winnr()
  vim.cmd('ToggleTermSendCurrentLine')
  vim.cmd(winnr .. 'wincmd w')
end
set_keymap('n', '<Leader>j', _toggleterm_run, {desc = 'ToggleTermSendCurrentLine'})

-- toggleterm:lazygit
local lazygit = require'toggleterm.terminal'.Terminal:new {
  cmd = 'lazygit',
  hidden = true,
  direction = 'float'
}
local function lazygit_toggle()
  lazygit:toggle()
end
set_keymap(
  'n', '<Leader>gl',
  lazygit_toggle,
  {desc = 'lazygit', silent = true}
)


--[[ fuzzyfinder settings ]]
-- telescope
local Telescope = require'telescope'
local TelescopeBuiltin = require'telescope.builtin'
Telescope.setup()
Telescope.load_extension('frecency')
Telescope.load_extension('fzf')
set_keymap('n', '<C-P>', '<Nop>')
for key, val in pairs {
  ['<C-P>b'] = {'buffers'},
  ['<C-P>c'] = {'commands'},
  ['<C-P>f'] = {'find_files'},
  ['<C-P>g'] = {'live_grep'},
  ['<C-P>h'] = {'help_tags'},
  ['<C-P>k'] = {'keymaps'},
  ['<C-P>l'] = {'git_files'},
  ['<C-P>m'] = {'mru', Telescope.extensions.frecency.frecency},
  ['<C-P>p'] = {'registers'},
  ['<C-P>r'] = {'resume'},
  ['<C-P>t'] = {'treesitter'},
  ['<C-P>/'] = {'current_buffer_fuzzy_find'},
} do
  set_keymap(
    'n', key,
    val[2] or TelescopeBuiltin[val[1]],
    {desc = 'telescope ' .. val[1]}
  )
end


--[[ LSP settings ]]
-- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
require("mason").setup()
local LspSaga = require'lspsaga'
LspSaga.init_lsp_saga({
  code_action_lightbulb = { virtual_text = false, sign = false }
})
local Illuminate = require'illuminate'
set_keymap('n', '<Leader>e', vim.diagnostic.open_float, {silent = true, desc = 'float diagnostic'})
set_keymap('n', '[d', vim.diagnostic.goto_prev, {silent = true, desc = 'previous diagnostic'})
set_keymap('n', ']d', vim.diagnostic.goto_next, {silent = true, desc = 'next diagnositc'})
set_keymap('n', '<Leader>q', vim.diagnostic.setloclist, {silent = true, desc = 'add buffer diagnositcs to the location list'})
set_keymap('n', '<C-H>', function() Illuminate.next_reference({reverse=true, wrap=true}) end, {desc = 'previous references'})
set_keymap('n', '<C-L>', function() Illuminate.next_reference({wrap=true}) end, {desc = 'next reference'})

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local OPTS = {silent = true, buffer = bufnr}
  set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', OPTS)
  set_keymap('n', 'gd', TelescopeBuiltin.lsp_definitions, OPTS)
  -- set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', OPTS)
  set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', OPTS)
  set_keymap('n', 'gi', TelescopeBuiltin.lsp_implementations, OPTS)
  -- set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', OPTS)
  set_keymap('n', '<C-K>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', OPTS)
  set_keymap('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', OPTS)
  set_keymap('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', OPTS)
  set_keymap('n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', OPTS)
  set_keymap('n', '<Leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', OPTS)
  set_keymap('n', '<Leader>rn', require'lspsaga.rename'.lsp_rename, OPTS)
  -- set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', OPTS)
  set_keymap('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', OPTS)
  set_keymap('n', 'gr', TelescopeBuiltin.lsp_references, OPTS)
  -- set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', OPTS)
  set_keymap('n', '<Leader>lf', '<cmd>lua vim.lsp.buf.formatting()<CR>', OPTS)

  -- Highlighting
  Illuminate.on_attach(client)
end

local Lspconfig = require'lspconfig'
local function setup_lsp(lsp, config)
  local config2 = {on_attach = on_attach, flags = {debounce_text_changes = 150}}
  for k, v in pairs(config or {}) do
    config2[k] = v
  end
  Lspconfig[lsp].setup(config2)
end

for lsp, config in pairs{
  pyright = {}, -- pip install --user pyright
  r_language_server = {}, -- R -e "remotes::install_github('languageserver')"
  denols = {},
  bashls = {filetypes = {'sh', 'bash', 'zsh'}}, -- npm i -g bash-language-server
  sumneko_lua = {}, -- pacman -S lua-language-server
  gopls = {},
} do
  setup_lsp(lsp, config)
end


--[[ autocompletion settings ]]
-- ddc
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/ddc.vim')
