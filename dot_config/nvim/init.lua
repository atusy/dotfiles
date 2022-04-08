vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.splitright = true
vim.opt.hlsearch = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.showmatch = true
vim.opt.matchtime = 1
vim.opt.guifont = {'PlemolJP Console', 'Cica'}
vim.opt.guifontwide = vim.opt.guifont:get()
vim.opt.pumheight = 10
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.clipboard:append('unnamedplus')
vim.opt.shell = 'zsh'

vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.autoread = true

local _nvim_set_keymap = vim.api.nvim_set_keymap
local function _set_keymap(mode, lhs, rhs, ops)
  _nvim_set_keymap(mode, lhs, rhs, ops or {noremap = true})
end

vim.g.mapleader = ' '
_set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
_set_keymap('n', 'x', '"_x')
_set_keymap('n', 'X', '"_X')
_set_keymap('n', 'gy', '"+y')
_set_keymap('n', 'gY', '"+Y')
_set_keymap('v', 'gy', '"+y')
_set_keymap('v', 'gY', '"+Y')
_set_keymap('c', '<C-A>', '<Home>')
_set_keymap('c', '<C-E>', '<End>')
_set_keymap('n', '<Leader>bd', ':up | bd<CR>')
_set_keymap('n', '<Leader>bD', ':bd!<CR>')

vim.cmd([[autocmd TermOpen * startinsert]])

function _init_lua()
  vim.cmd '!chezmoi apply'
  vim.cmd 'source $MYVIMRC'
end
vim.api.nvim_exec([[
  command! -nargs=0 InitLua :lua _init_lua()
]], false)

-- PLUGIN SETTINGS
if vim.fn.empty(vim.fn.glob(vim.fn.stdpath('data') .. '/site/autoload/jetpack.vim')) == 1 then
vim.api.nvim_exec(
  [[
    let jetpack = stdpath('data') . '/site/autoload/jetpack.vim'
    autocmd VimEnter * JetpackSync | source $MYVIMRC
    silent execute '!curl -fLo '.jetpack.' --create-dirs  https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim'
    silent execute '!curl -fLo "$HOME/.config/nvim/lua/jetpack.lua" --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/lua/jetpack.lua'
  ]],
  false
)
end
require('jetpack').startup(function(use)
  use 'tpope/vim-commentary'

  if vim.g.vscode == 1 then
    use 'asvetliakov/vim-easymotion'
    _set_keymap('', '<Leader>f', "<Plug>(easymotion-f)", {})
    _set_keymap('', '<Leader>F', "<Plug>(easymotion-f)", {})
    return
  end

  use 'ulwlu/elly.vim'
  use 'phaazon/hop.nvim'
  use 'haya14busa/vim-edgemotion'
  use "nathom/filetype.nvim"
  use 'feline-nvim/feline.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use 'romgrk/barbar.nvim'
  use 'lambdalisue/fern.vim'
  use 'lambdalisue/gin.vim'
  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-lua/plenary.nvim' -- required by gitsigns
  use 'lewis6991/gitsigns.nvim'
  use 'simeji/winresizer'
  use 'akinsho/toggleterm.nvim'
  use 'machakann/vim-sandwich'
  use 'AndrewRadev/bufferize.vim'
  use 'vim-denops/denops.vim'

  use 'neovim/nvim-lspconfig'
  use 'williamboman/nvim-lsp-installer'

  use 'Shougo/ddc.vim'
  use 'Shougo/ddc-around'
  use 'Shougo/ddc-cmdline'
  use 'Shougo/ddc-cmdline-history'
  --use 'Shougo/ddc-nextword'
  use 'Shougo/ddc-matcher_head'  -- 入力中の単語を補完
  use 'Shougo/ddc-nvim-lsp'  -- 入力中の単語を補完
  use 'LumaKernel/ddc-file'  -- Suggest file paths
  use 'Shougo/ddc-converter_remove_overlap' -- remove duplicates
  use 'Shougo/ddc-sorter_rank'  -- Sort suggestions
  use 'Shougo/pum.vim'  -- Show popup window
  use 'matsui54/denops-signature_help'
  use 'matsui54/denops-popup-preview.vim'
end)

-- EARLY RETURN FOR VSCODE
if vim.g.vscode == 1 then return end

-- Elly SETTINGS
vim.cmd([[colorscheme elly]])

-- Hop (Easymotion) SETTINGS
require('hop').setup()
_set_keymap('', '<Leader>f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", {})
_set_keymap('', '<Leader>F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", {})

-- Edgemotion SETTINGS
_set_keymap('', '<Leader>]', '<Plug>(edgemotion-j)', {})
_set_keymap('', '<Leader>[', '<Plug>(edgemotion-k)', {})

-- feline SETTINGS
require('feline').setup({
  preset = 'noicon'
})

-- Fern SETTINGS
_set_keymap('n', '<C-F>', ':Fern . -drawer<CR>', {})
vim.api.nvim_exec([[
function! s:init_fern() abort
  set nornu
  set nonu
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END
]], false)

-- barbar SETTINGS
_set_keymap('n', '<C-H>', ':BufferPrevious<CR>', {noremap = true, silent = true})
_set_keymap('n', '<C-L>', ':BufferNext<CR>', {noremap = true, silent = true})
_set_keymap('n', '<Leader>bc', ':up | BufferClose<CR>')
_set_keymap('n', '<Leader>bC', ':BufferClose!<CR>')
_set_keymap('n', '<Leader>bp', ':BufferPick<CR>')
_set_keymap('n', '<Leader>bo', ':wa | BufferCloseAllButCurrent<CR>')
vim.api.nvim_exec([[
  let bufferline = get(g:, 'bufferline', {})
  let bufferline.icon_separator_active = ' ❯❯'
  let bufferline.icon_separator_inactive = ''
  let bufferline.icon_close_tab = '×'
  hi default link BufferVisible BufferCurrent
  hi default link BufferVisibleSign BufferCurrent
]], false)

-- treesitter SETTINGS
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = 'maintained'
})

-- gitsigns SETTINGS
require('gitsigns').setup()

--toggleterm SETTINGS
require("toggleterm").setup{
  open_mapping = '<C-S>'
}
function _toggleterm_run() 
  local winnr = vim.fn.winnr()
  vim.cmd("ToggleTermSendCurrentLine")
  vim.cmd(winnr .. "wincmd w")
end
_set_keymap('n', '<Leader>j', '<cmd>lua _toggleterm_run()<CR>', { noremap = true} )
_set_keymap('v', '<Leader>j', ":ToggleTermSendVisualLines<CR>", { noremap = true} )

local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float"
})
function _lazygit_toggle()
  lazygit:toggle()
end
_set_keymap("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})

-- sandwich SETTINGS
vim.api.nvim_exec([[let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)]], false)

-- lsp SETTINGS
-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
_set_keymap('n', '<Leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
_set_keymap('n', '<Leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local function lspsetup(lsp, config)
  local config2 = { on_attach = on_attach, flags = { debounce_text_changes = 150 } }
  for k, v in pairs(config or {}) do
    config2[k] = v
  end
  require('lspconfig')[lsp].setup(config2)
end

for lsp, config in pairs{ 
  pyright = {},
  --r_language_server = { cmd = {"R", "--slave", "-e", "options(languageserver.rich_documentation = FALSE); languageserver::run()" } },
  r_language_server = {},
  tsserver = {},
} do
  lspsetup(lsp, config)
end

-- ddc SETTINGS
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/ddc.vim')
