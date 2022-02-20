set sh=zsh
set whichwrap=h,l
set relativenumber
set number
set tabstop=2
set shiftwidth=2
set splitright
set clipboard+=unnamedplus "Linux requires xclip
set hlsearch
nnoremap <ESC><ESC> :nohlsearch<CR>
set laststatus=2 "always
set showcmd
set background=dark
set wildmenu
set backspace=indent,eol,start "<BS>で消せる対象
set ruler "show position of cursor
set showmatch "indicate who is paired with the bracket under the cursor
set matchtime=1 "showmatch within matchtime * 0.1 sec
set guifont=Cica "DroidSansMono\ Nerd\ Font\ 13
set guifontwide=Cica "DroidSansMono\ Nerd\ Font\ 13
set pumheight=10 "Upper limit of completion list
set mouse=a
set termguicolors
set hidden " Allow switching buffers without writing

set autoindent
set incsearch
set expandtab
set list listchars=tab:\▸\-

let mapleader = " "

" delete without register to avoid overwriting system clipboard
nnoremap x "_x
nnoremap X "_X

" https://stackoverflow.com/a/21000307/12901910
nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

" terminal
autocmd TermOpen * startinsert
tnoremap <Esc> <C-\><C-n>
" Open terminal at the bottom
command! -nargs=* T split | wincmd j | resize 20 | terminal <args>


" PLUGIN SETTINGS
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/jetpack.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/jetpack.vim --create-dirs  https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim'
  autocmd VimEnter * JetpackSync | source $MYVIMRC
endif
call jetpack#begin()
Jetpack 'feline-nvim/feline.nvim'
Jetpack 'zefei/vim-wintabs'
Jetpack 'tpope/vim-commentary'
Jetpack 'neoclide/coc.nvim', {'branch': 'release'}
Jetpack 'lambdalisue/fern.vim'
Jetpack 'ryanoasis/vim-devicons'
Jetpack 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Jetpack 'airblade/vim-gitgutter'
Jetpack 'easymotion/vim-easymotion'
call jetpack#end()

" feline SETTINGS
lua << EOF
require('feline').setup({
  preset = 'noicon'
})
EOF

" wintabs SETTINGS
" :help wintabs-commands
map <C-H> <Plug>(wintabs_next)
map <C-L> <Plug>(wintabs_previous)
map <C-T>c <Plug>(wintabs_close)
map <C-T>u <Plug>(wintabs_undo)
map <C-T>o <Plug>(wintabs_only)
map <C-W>c <Plug>(wintabs_close_window)
map <C-W>o <Plug>(wintabs_only_window)

" Fern SETTINGS
nmap <C-f> :Fern . -drawer<CR>

" Easymotion SETTINGS
" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)

" s{char}{char} to move to {char}{char}
nmap <Leader>s <Plug>(easymotion-overwin-f2)

" Move to line
map <Leader>l <Plug>(easymotion-bd-jk)
nmap <Leader>l <Plug>(easymotion-overwin-line)

" Move to word
map  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)

" Esc SETTINGS
inoremap jk <Esc>
inoremap jj <Esc>

" /// Enable Netrw (default file browser)
" filetype plugin on
" /// Netrw SETTINGS
" let g:netwr_banner = 0
" let g:netrw_liststyle = 3
" let g:netrw_browse_split = 4
" let g:netrw_winsize = 30
" let g:netrw_sizestyle = "H"
" let g:netrw_timefmt = "%Y/%m/%d(%a) %H:%M:%S"
" let g:netrw_preview = 1

"/// SPLIT BORDER SETTINGS
hi VertSplit cterm=none

" treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  },
  ensure_installed = 'all'
}
EOF

