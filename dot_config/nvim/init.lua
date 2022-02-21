vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.splitright = true
vim.opt.hlsearch = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.showmatch = true
vim.opt.matchtime = 1
vim.opt.guifont = {'Cica'}
vim.opt.guifontwide = vim.opt.guifont:get()
vim.opt.pumheight = 10
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.clipboard:append('unnamedplus')

vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = false

vim.g.mapleader = ' '

vim.api.nvim_set_keymap('n', 'x', '"_x', { noremap = true} )
vim.api.nvim_set_keymap('n', 'X', '"_X', { noremap = true} )

-- PLUGIN SETTINGS
vim.api.nvim_exec([[
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/jetpack.vim'))
  autocmd VimEnter * JetpackSync | source $MYVIMRC
  silent execute '!curl -fLo '.data_dir.'/autoload/jetpack.vim --create-dirs  https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim'
  silent execute '!curl -fLo ~/.config/nvim/lua/jetpack.lua --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/lua/jetpack.lua'
endif
]],
false)
require('jetpack').startup(function(use)
  use 'feline-nvim/feline.nvim'
  use 'zefei/vim-wintabs'
  use 'tpope/vim-commentary'
  use {'neoclide/coc.nvim', branch = 'release'}
  use 'lambdalisue/fern.vim'
  use {'nvim-treesitter/nvim-treesitter', ['do'] = ':TSUpdate'}
  use 'airblade/vim-gitgutter'
  use 'easymotion/vim-easymotion'
  use 'haya14busa/vim-edgemotion'
  use 'simeji/winresizer'
end)

-- feline SETTINGS
require('feline').setup({
  preset = 'noicon'
})

-- wintabs SETTINGS
for k, v in pairs({
  ['<C-H>'] = '<Plug>(wintabs_next)',
  ['<C-L>'] = '<Plug>(wintabs_previous)',
  ['<C-L>'] = '<Plug>(wintabs_previous)',
  ['<C-T>c'] = '<Plug>(wintabs_close)',
  ['<C-T>u'] = '<Plug>(wintabs_undo)',
  ['<C-T>o'] = '<Plug>(wintabs_only)',
  ['<C-W>c'] = '<Plug>(wintabs_close_window)',
  ['<C-W>o'] = '<Plug>(wintabs_only_window)',
  ['<C-T>c'] = '<Plug>(wintabs_close)',
  ['<C-T>u'] = '<Plug>(wintabs_undo)',
  ['<C-T>o'] = '<Plug>(wintabs_only)',
  ['<C-W>c'] = '<Plug>(wintabs_close_window)',
  ['<C-W>o'] = '<Plug>(wintabs_only_window)'
}) do
  vim.api.nvim_set_keymap('', k, v, {})
end

-- Fern SETTINGS
vim.api.nvim_set_keymap('n', '<C-F>', ':Fern . -drawer<CR>', {})

-- Easymotion SETTINGS
vim.api.nvim_set_keymap('', '<Leader>f', '<Plug>(easymotion-bd-f)', {})
vim.api.nvim_set_keymap('n', '<Leader>f', '<Plug>(easymotion-overwin-f)', {})
vim.api.nvim_set_keymap('n', '<Leader>s', '<Plug>(easymotion-overwin-f2)', {})

-- Edgemotion SETTINGS
vim.api.nvim_set_keymap('', '<Leader>j', '<Plug>(edgemotion-j)', {})
vim.api.nvim_set_keymap('', '<Leader>k', '<Plug>(edgemotion-k)', {})

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = 'all'
})
