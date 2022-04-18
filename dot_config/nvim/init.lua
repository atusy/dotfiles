local vim = vim -- minimize LSP warning

vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.hlsearch = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.showmatch = true
vim.opt.matchtime = 1
vim.opt.guifont = {'UDEV Gothic', 'PlemolJP Console', 'Cica'}
vim.opt.guifontwide = vim.opt.guifont:get()
vim.opt.pumheight = 10
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.shell = 'zsh'
vim.opt.updatetime = 300 -- recommended by vgit
vim.opt.incsearch = true -- false reccomended by vgit
vim.opt.signcolumn = 'yes'

vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.autoread = true

-- nvim-remote for edit-commandline zle
-- <Space>bd will update, wipe buffer, and go back to the caller terminal
if vim.fn.executable('nvr') == 1 then
  function Write_and_bufferwipe()
    local winnr = vim.b.zsh_cmdline_parent_winnr
    vim.cmd("w | bw | " .. winnr .. "wincmd w")
  end
  vim.env.EDITOR_CMD = 'nvr -cc "below 5split" -c "set filetype=zsh_cmdline" --remote-wait-silent'
  vim.api.nvim_exec([[
    augroup zsh-cmdline
      autocmd! *
      autocmd FileType zsh_cmdline let b:zsh_cmdline_parent_winnr = get(b:, 'zsh_cmdline_parent_winnr', winnr('#'))
      autocmd FileType zsh_cmdline nnoremap <buffer> <Space>bd <Cmd>lua Write_and_bufferwipe()<CR>
      autocmd FileType zsh_cmdline set filetype=zsh
    augroup END
  ]], false)
end

local _nvim_set_keymap = vim.api.nvim_set_keymap
local function _set_keymap(mode, lhs, rhs, opts)
  _nvim_set_keymap(mode, lhs, rhs, opts or {noremap = true})
end

vim.g.mapleader = ' '
_set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
_set_keymap('n', 'x', '"_x')
_set_keymap('n', 'X', '"_X')
_set_keymap('n', 'gf', 'gF')
_set_keymap('n', 'gy', '"+y')
_set_keymap('n', 'gY', '"+Y')
_set_keymap('v', 'gy', '"+y')
_set_keymap('v', 'gY', '"+Y')
_set_keymap('c', '<C-A>', '<Home>')
_set_keymap('c', '<C-E>', '<End>')
--_set_keymap('t', '<ESC>', '<C-\\><C-N>')  -- conflicts with some TUIs such as lazygit
_set_keymap('t', '<C-W>', "'<Cmd>wincmd ' .. getcharstr() .. '<CR>'", { expr = true })

vim.api.nvim_create_augroup('termopen', {clear = true})
vim.api.nvim_create_autocmd({'TermOpen'}, {pattern = '*', command = 'startinsert'})

vim.api.nvim_create_user_command(
  'ApplyMYVIMRC',
  function()
    vim.cmd '!chezmoi apply'
    vim.cmd 'source $MYVIMRC'
  end,
  {}
)

-- PLUGIN SETTINGS
if vim.fn.empty(vim.fn.glob(vim.fn.stdpath('data') .. '/site/autoload/jetpack.vim')) == 1 then
  vim.api.nvim_exec([[
    let jetpack = stdpath('data') . '/site/autoload/jetpack.vim'
    autocmd VimEnter * JetpackSync | source $MYVIMRC
    silent execute '!curl -fLo '.jetpack.' --create-dirs  https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim'
    silent execute '!curl -fLo "$HOME/.config/nvim/lua/jetpack.lua" --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/lua/jetpack.lua'
  ]], false)
end
require('jetpack').startup(function(use)
  -- used also in VS Code
  use 'tpope/vim-commentary'
  use 'jghauser/mkdir.nvim'

  if vim.g.vscode == 1 then
    use 'asvetliakov/vim-easymotion'
    _set_keymap('', 'f', "<Plug>(easymotion-f)", {})
    _set_keymap('', 'F', "<Plug>(easymotion-f)", {})
    return
  end

  -- basic dependencies
  use 'kyazdani42/nvim-web-devicons' -- for lualine
  use 'nvim-lua/plenary.nvim' -- for gitsigns, vgit
  use 'vim-denops/denops.vim'

  -- utils
  use "nathom/filetype.nvim"
  use 'lambdalisue/fern.vim'
  use 'simeji/winresizer'
  use 'AndrewRadev/bufferize.vim'
  use 'moll/vim-bbye'

  -- colorscheme
  use '4513ECHO/vim-colors-hatsunemiku'

  -- highlight
  use 'RRethy/vim-illuminate'
  use 'norcalli/nvim-colorizer.lua'

  -- statusline
  use 'feline-nvim/feline.nvim'

  -- bufferline
  -- use 'romgrk/barbar.nvim'

  -- motion
  use 'haya14busa/vim-edgemotion'
  use 'phaazon/hop.nvim'

  -- fuzzy finder
  use 'ctrlpvim/ctrlp.vim'
  use 'nvim-telescope/telescope.nvim'
  use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

  -- git
  use 'knsh14/vim-github-link'
  use 'lambdalisue/gin.vim'
  use 'tanvirtin/vgit.nvim'

  -- treesitter
  use {'nvim-treesitter/nvim-treesitter', commit = "6a437db0124823f9fe89c1de9a3b536ce1f103f3"}
  use 'yioneko/nvim-yati'
  use 'haringsrob/nvim_context_vt'
  use 'm-demare/hlargs.nvim'
  use 'romgrk/nvim-treesitter-context'
  use 'mfussenegger/nvim-treehopper'
  use 'David-Kunz/treesitter-unit'

  -- text object
  use 'machakann/vim-sandwich'

  -- terminal
  use 'akinsho/toggleterm.nvim'
  use 'Shougo/deol.nvim'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'williamboman/nvim-lsp-installer'
  use 'folke/lsp-colors.nvim'

  -- ddc
  use 'Shougo/ddc.vim'
  use 'Shougo/ddc-around'
  use 'Shougo/ddc-cmdline'
  use 'Shougo/ddc-cmdline-history'
  -- use 'Shougo/ddc-nextword'
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

--[[ colorscheme SETTINGS ]]
local default_colorscheme = "hatsunemiku"
vim.cmd("colorscheme " .. default_colorscheme)
require'colorizer'.setup()
vim.g.illuminate_ftblacklist = {'fern'}

-- Hop SETTINGS
require('hop').setup()
local function hopper(direction)
  return function()
    require'hop'.hint_char1 {
      direction = require'hop.hint'.HintDirection[direction],
      current_line_only = true
    }
  end
end
_set_keymap('', 'f', '', {callback = hopper('AFTER_CURSOR'), desc = 'Hop after'})
_set_keymap('', 'F', '', {callback = hopper('BEFORE_CURSOR'), desc = 'Hop before'})

-- Edgemotion SETTINGS
_set_keymap('', '<Leader>]', '<Plug>(edgemotion-j)', {})
_set_keymap('', '<Leader>[', '<Plug>(edgemotion-k)', {})

-- feline SETTINGS
require('feline').setup({
  preset = 'noicon'
})

-- Fern SETTINGS
_set_keymap('n', '<C-F>', ':Fern . -drawer -reveal=%<CR>')
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

-- Bbye SETTINGS
_set_keymap('n', '<Leader>bd', ':up | Bdelete<CR>')
_set_keymap('n', '<Leader>bD', ':Bdelete!<CR>')

-- barbar SETTINGS
-- _set_keymap('n', '<C-H>', ':BufferPrevious<CR>', {noremap = true, silent = true})
-- _set_keymap('n', '<C-L>', ':BufferNext<CR>', {noremap = true, silent = true})
-- _set_keymap('n', '<Leader>bd', ':up | BufferClose<CR>')
-- _set_keymap('n', '<Leader>bD', ':BufferClose!<CR>')
-- _set_keymap('n', '<Leader>bp', ':BufferPick<CR>')
-- _set_keymap('n', '<Leader>bo', ':wa | BufferCloseAllButCurrent<CR>')
-- vim.api.nvim_exec([[
--   let bufferline = get(g:, 'bufferline', {})
--   let bufferline.icon_separator_active = ' ❯❯'
--   let bufferline.icon_separator_inactive = ''
--   let bufferline.icon_close_tab = '×'
-- ]], false)

-- treesitter SETTINGS
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'bash', 'bibtex', 'c', 'c_sharp', 'cmake', 'cpp', 'css', 'dockerfile',
    'dot', 'go', 'gomod', 'gowork', 'graphql', 'haskell', 'help', 'html',
    'http', 'java', 'javascript', 'json', 'json5', 'julia', 'latex', 'lua',
    'make', 'markdown', 'ninja', 'nix', 'python', 'r', 'regex', 'ruby', 'rust',
    'scss', 'teal', 'toml', 'tsx', 'typescript', 'vala', 'vim', 'vue', 'yaml'
  },
  highlight = { enable = true },
  indent = { enable = true },
  yati = { enable = true },
})
local ft_to_parser = require"nvim-treesitter.parsers".filetype_to_parsername
ft_to_parser.zsh = "bash"
require('nvim_context_vt').setup({enabled = true})
require('hlargs').setup()
require('treesitter-context').setup()
_set_keymap('o', 'm', ":<C-U>lua require('tsht').nodes()<CR>", {noremap=true, silent=true})
_set_keymap('v', 'm', ":lua require('tsht').nodes()<CR>", {noremap=true, silent=true})
_set_keymap('x', 'iu', ':lua require"treesitter-unit".select()<CR>', {noremap=true})
_set_keymap('x', 'au', ':lua require"treesitter-unit".select(true)<CR>', {noremap=true})
_set_keymap('o', 'iu', ':<c-u>lua require"treesitter-unit".select()<CR>', {noremap=true})
_set_keymap('o', 'au', ':<c-u>lua require"treesitter-unit".select(true)<CR>', {noremap=true})

-- vgit SETTINGS
require('vgit').setup({
  keymaps = {
    ['n <leader>gj'] = 'hunk_down',
    ['n <leader>gk'] = 'hunk_up',
    ['n <leader>gs'] = 'buffer_hunk_stage',
    ['n <leader>gr'] = 'buffer_hunk_reset',
  }
})

--toggleterm SETTINGS
require("toggleterm").setup{
  open_mapping = '<C-I>'
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
_set_keymap("n", "<Leader>gl", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})

-- sandwich SETTINGS
vim.api.nvim_exec([[let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)]], false)

-- telescope SETTINGS
require('telescope').setup {
  extensions = {
    fzf_writer = {
      minimum_grep_characters = 2,
      minimum_files_characters = 2,
    }
  }
}
require('telescope').load_extension('fzf')
_set_keymap('n', '<Leader>ff', '<Cmd>Telescope find_files<CR>')
_set_keymap('n', '<Leader>fg', '<Cmd>Telescope live_grep<CR>')
_set_keymap('n', '<Leader>fb', '<Cmd>Telescope buffers<CR>')
_set_keymap('n', '<Leader>fh', '<Cmd>Telescope help_tags<CR>')
_set_keymap('n', '<Leader>ft', '<Cmd>lua require"telescope.builtin".treesitter()<CR>')
_set_keymap('n', '<Leader>fr', '<Cmd>lua require"telescope.builtin".lsp_references()<CR>')

-- lsp SETTINGS
-- Highlights.
require("lsp-colors").setup()
vim.api.nvim_exec([[
  hi illuminatedWordDefault guibg=#383D47
  hi link illuminatedWord illuminatedWordDefault
  hi link LspReferenceText illuminatedWord
  hi link LspReferenceWrite illuminatedWord
  hi link LspReferenceRead illuminatedWord
  augroup illuminate-by-mode
    autocmd ModeChanged *:[ivV\x16]* hi illuminatedWord guibg=#00000000
    autocmd ModeChanged [ivV\x16]*:* hi link illuminatedWord illuminatedWordDefault
  augroup END
]], false)

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
_set_keymap('n', '<Leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
_set_keymap('n', '<Leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
_set_keymap('n', '<a-l>', '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', {noremap=true})
_set_keymap('n', '<a-h>', '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>', {noremap=true})

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
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>fo', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

  -- Highlighting
  require'illuminate'.on_attach(client)
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
  pyright = {}, -- pip install --user pyright
  --r_language_server = { cmd = {"R", "--slave", "-e", "options(languageserver.rich_documentation = FALSE); languageserver::run()" } },
  r_language_server = {}, -- R -e "remotes::install_github('languageservre')"
  tsserver = {},
  bashls = {filetypes = {"sh", "bash", "zsh"}}, -- npm i -g bash-language-server
  sumneko_lua = {}, -- pacman -S lua-language-server
} do
  lspsetup(lsp, config)
end

-- ddc SETTINGS
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/ddc.vim')
