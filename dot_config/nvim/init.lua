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
vim.opt.expandtab = false
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.autoread = true

vim.g.mapleader = ' '

vim.api.nvim_set_keymap('n', 'x', '"_x', { noremap = true} )
vim.api.nvim_set_keymap('n', 'X', '"_X', { noremap = true} )
vim.api.nvim_set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>', { noremap = true })
vim.api.nvim_set_keymap('t', '<C-w>', "'<Cmd>wincmd ' .. getcharstr() .. '<CR>'", { expr = true })

vim.cmd([[autocmd TermOpen * startinsert]])

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
    vim.api.nvim_set_keymap('', '<Leader>f', "<Plug>(easymotion-f)", {})
    vim.api.nvim_set_keymap('', '<Leader>F', "<Plug>(easymotion-f)", {})
    return
  end

  use 'phaazon/hop.nvim'
  use 'haya14busa/vim-edgemotion'
  use "nathom/filetype.nvim"
  use 'feline-nvim/feline.nvim'
  use 'zefei/vim-wintabs'
  use {'neoclide/coc.nvim', branch = 'release'}
  use 'lambdalisue/fern.vim'
  use {'nvim-treesitter/nvim-treesitter', ['do'] = ':TSUpdate'}
  use 'nvim-lua/plenary.nvim' -- required by gitsigns
  use 'lewis6991/gitsigns.nvim'
  use 'simeji/winresizer'
  use 'akinsho/toggleterm.nvim'
  use 'machakann/vim-sandwich'
  use 'AndrewRadev/bufferize.vim'
end)

-- EARLY RETURN FOR VSCODE
if vim.g.vscode == 1 then return end

-- Hop (Easymotion) SETTINGS
require('hop').setup()
vim.api.nvim_set_keymap('', '<Leader>f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('', '<Leader>F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('', '<Leader>s', "<cmd>lua require'hop'.hint_char2({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('', '<Leader>S', "<cmd>lua require'hop'.hint_char2({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", {})

-- Edgemotion SETTINGS
vim.api.nvim_set_keymap('', '<Leader>j', '<Plug>(edgemotion-j)', {})
vim.api.nvim_set_keymap('', '<Leader>k', '<Plug>(edgemotion-k)', {})

-- feline SETTINGS
require('feline').setup({
  preset = 'noicon'
})

-- Fern SETTINGS
vim.api.nvim_set_keymap('n', '<C-F>', ':Fern . -drawer<CR>', {})

-- wintabs SETTINGS
for k, v in pairs({
  ['<C-L>'] = '<Plug>(wintabs_next)',
  ['<C-H>'] = '<Plug>(wintabs_previous)',
  ['<C-T>c'] = '<Plug>(wintabs_close)',
  ['<C-T>u'] = '<Plug>(wintabs_undo)',
  ['<C-T>o'] = '<Plug>(wintabs_only)',
  ['<C-W>c'] = '<Plug>(wintabs_close_window)',
  ['<C-W>o'] = '<Plug>(wintabs_only_window)',
}) do
  vim.api.nvim_set_keymap('', k, v, {})
end

-- treesitter SETTINGS
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = 'all'
})

-- gitsigns SETTINGS
require('gitsigns').setup()

--toggleterm SETTINGS
require("toggleterm").setup{
  open_mapping = '<C-S>'
}

local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float"
})
function _lazygit_toggle()
  lazygit:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})

-- sandwich SETTINGS
vim.api.nvim_exec([[let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)]], false)
