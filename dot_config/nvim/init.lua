--[[
TODO

# quickfix

## Plugin

https://github.com/thinca/vim-qfreplace
https://github.com/itchyny/vim-qfedit

--]]

--[[ tricks ]]
-- TODO: set up diagnostics based on https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#sumneko_lua
local vim = vim -- minimize LSP warning

-- [[ helpers ]]
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
for _, k in ipairs({'s', ',', ';'}) do
  set_keymap('n', '<A-' .. k .. '>', k)
end
set_keymap('n', 's', '<Nop>')     -- be prefix for sandwich
set_keymap('n', 'qa', '<Nop>')    -- avoid typo of :qa
set_keymap('n', ';', ':')
set_keymap('n', '<C-G><C-G>', '<C-G><Cmd>let @+ = expand("%")<CR>')
set_keymap('', '-', '"_')         -- shortcut to blackhole register
set_keymap('', '+', '"+')         -- shortcut to clipboard+ register
set_keymap('n', '<ESC><ESC>', ':nohlsearch<CR>')
set_keymap('n', 'x', '"_x')
set_keymap('n', 'X', '"_X')
set_keymap('n', 'gf', 'gF')
set_keymap('n', '<Left>', '^')
set_keymap('n', '<Right>', '$')
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
    vim.cmd('up')
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
  use 'vim-denops/denops.vim'
  use 'kana/vim-submode'

  -- utils
  use 'tpope/vim-commentary'
  use 'nathom/filetype.nvim'
  use 'lambdalisue/guise.vim'
  use 'lambdalisue/fern.vim'
  use 'segeljakt/vim-silicon'  -- pacman -S silicon

  -- windows and buffers
  use 'tkmpypy/chowcho.nvim'
  use 'moll/vim-bbye'
  use 'AndrewRadev/bufferize.vim'

  -- better something
  use 'wsdjeg/vim-fetch'             -- :e with linenumber
  use 'jghauser/mkdir.nvim'          -- :w with mkdir
  use 'haya14busa/vim-asterisk'      -- *
  use 'lambdalisue/readablefold.vim'

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
  use 'ggandor/leap.nvim'
  use 'ggandor/leap-ast.nvim'

  -- fuzzy finder
  use 'nvim-telescope/telescope.nvim'
  use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}

  -- git
  use 'tpope/vim-fugitive'
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
  use 'ii14/emmylua-nvim'

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
  use 'tani/ddc-fuzzy'
  use 'matsui54/denops-signature_help'
  use 'matsui54/denops-popup-preview.vim'

  -- language specific
  -- go
  use 'mattn/vim-goimports'
end)


--[[ colorscheme/highlight ]]
-- params
local DEFAULT_COLORSCHEME = 'hatsunemiku'
local ALTERNATIVE_COLORSCHEME = 'gruvbox'
local ILLUMINATION = {bg="#383D47"}

-- set colorscheme
local setup_hlargs = require'hlargs'.setup
local setup_colorizer = require'colorizer'.setup
local setup_lsp_colors = require'lsp-colors'.setup
local function set_colorscheme(nm)
  vim.cmd('colorscheme ' .. nm)
  setup_hlargs()
  setup_colorizer()
  setup_lsp_colors()
  vim.api.nvim_set_hl(0, "IlluminatedWordText", ILLUMINATION)
  vim.api.nvim_set_hl(0, "IlluminatedWordRead", ILLUMINATION)
  vim.api.nvim_set_hl(0, "IlluminatedWordWrite", ILLUMINATION)
  vim.api.nvim_set_hl(0, "Folded", ILLUMINATION)
end
set_colorscheme(DEFAULT_COLORSCHEME)

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
      local FILETYPE = vim.api.nvim_buf_get_option(0, "filetype")
      local BUFTYPE = vim.api.nvim_buf_get_option(0, "buftype")
      local CWD = vim.fn.getcwd()
      local COLORSCHEME = (
        FILE == '' or
        FILETYPE == 'gitcommit' or
        FILETYPE == 'gitrebase' or
        BUFTYPE ~= '' or
        CWD == string.sub(FILE, 1, string.len(CWD)) or
        '/tmp/' == string.sub(FILE, 1, 5)
      ) and DEFAULT_COLORSCHEME or ALTERNATIVE_COLORSCHEME

      -- Apply colorscheme and some highlight settings
      if COLORSCHEME ~= vim.api.nvim_exec('colorscheme', true) then
        set_colorscheme(COLORSCHEME)
      end
    end
  }
)

-- illuminate
local Illuminate = require'illuminate'
Illuminate.configure({
  filetype_denylist = {'fugitive', 'fern'},
  modes_allowlist = {'n'}
})
set_keymap('n', '<C-H>', Illuminate.goto_prev_reference, {desc = 'previous references'})
set_keymap('n', '<C-L>', Illuminate.goto_next_reference, {desc = 'next reference'})


--[[ window settings ]]
set_keymap({'', 't'}, '<C-Up>', '<Cmd>2wincmd +<CR>')
set_keymap({'', 't'}, '<C-Down>', '<Cmd>2wincmd -<CR>')
set_keymap({'', 't'}, '<C-Left>', '<Cmd>2wincmd <<CR>')
set_keymap({'', 't'}, '<C-Right>', '<Cmd>2wincmd ><CR>')

-- chowcho
require'chowcho'.setup({
  use_exclude_default = false,
  exclude = function(_, _) return false end}
)
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
set_keymap({'', 't'}, '<C-W><C-W>', _chowcho_focus)
set_keymap({'', 't'}, '<C-W>w', _chowcho_focus)

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
set_keymap({'', 't'}, '<C-W>c', _chowcho_hide)
set_keymap({'', 't'}, '<C-W><C-Space>', _chowcho_hide)
set_keymap({'', 't'}, '<C-W><Space>', _chowcho_hide)

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
set_keymap({'', 't'}, '<C-W>e', _chowcho_edit)
set_keymap({'', 't'}, '<C-W><C-E>', _chowcho_edit)

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
set_keymap({'', 't'}, '<C-W><C-X>', _chowcho_exchange)
set_keymap({'', 't'}, '<C-W>x', _chowcho_exchange)


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
      set_keymap('n', 'j', 'j<CR>zz<C-W>p', {buffer=0})
      set_keymap('n', 'k', 'k<CR>zz<C-W>p', {buffer=0})
    end
  }
)

--[[ textobj settings ]]
-- sandwich
vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])


--[[ motion settings ]]
-- hop
local Hop = require'hop'
Hop.setup()
local function hopper(direction, offset)
  local hint_char1 = Hop.hint_char1
  local opt = {
    direction = require'hop.hint'.HintDirection[direction],
    current_line_only = true,
    hint_offset = offset == nil and 0 or offset,
  }
  return function() hint_char1(opt) end
end
set_keymap('', '<Leader>f', 'f')
set_keymap('', '<Leader>F', 'F')
set_keymap('', '<leader>t', 't')
set_keymap('', '<Leader>T', 'T')
set_keymap('', 'f', hopper('AFTER_CURSOR'), {desc = 'Hop after'})
set_keymap('', 'F', hopper('BEFORE_CURSOR'), {desc = 'Hop before'})
set_keymap('', 't', hopper('AFTER_CURSOR', -1), {desc = 'Hop after'})
set_keymap('', 'T', hopper('BEFORE_CURSOR', 1), {desc = 'Hop before'})

-- leap
require('leap').setup({
  safe_labels = {},
})
vim.api.nvim_set_hl(0, 'LeapBackdrop', { fg = '#707070' })
set_keymap({'n', 'v', 'x'}, 'sj', '<Plug>(leap-forward)')
set_keymap({'n', 'v', 'x'}, 'sk', '<Plug>(leap-backward)')
set_keymap(
  {'n', 'v', 'x'},
  'sg',
  function()
    require('leap').leap { target_windows = vim.tbl_filter(
      function (win) return vim.api.nvim_win_get_config(win).focusable end,
      vim.api.nvim_tabpage_list_wins(0)
    )}
  end
)

-- edgemotion
set_keymap('', '<A-]>', '<Plug>(edgemotion-j)', {})
set_keymap('', '<A-[>', '<Plug>(edgemotion-k)', {})


--[[ statusline settings ]]
-- lualine
require'lualine'.setup {
  options = {theme = 'nord', component_separators = ''},
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{'filetype', icon_only = true}, {'filename', path=1}},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{'filetype', icon_only = true}, {'filename', path=1}},
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
vim.keymap.set(
  'n',
  '<Plug>(fern-action-open:chowcho)',
  function()
    local node = vim.api.nvim_exec([[
      let helper = fern#helper#new()
      echo helper.sync.get_selected_nodes()[0]["_path"]
    ]], true)
    require'chowcho'.run(function(n)
      vim.api.nvim_set_current_win(n)
      vim.cmd("edit " .. node)
    end)
  end,
  {}
)
vim.api.nvim_exec([[
  function! s:init_fern() abort
    setlocal nornu nonu cursorline signcolumn=auto
    nnoremap <buffer> <C-F> <C-W>p
    nmap <buffer> m <Nop>
    nmap <buffer><nowait> s <Plug>(fern-action-open:chowcho)
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
    'dot', 'go', 'gomod', 'gowork', 'graphql', 'haskell', 'hcl', 'help', 'html',
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
ft_to_parser.tf = 'hcl'
require'nvim_context_vt'.setup {
  enabled = true,
  disable_virtual_lines = true,
}
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
-- set_keymap('o', 'm', ':<C-U>lua require"tsht".nodes()<CR>', {silent = true})
-- set_keymap('v', 'm', ':lua require"tsht".nodes()<CR>', {silent = true})
set_keymap({'v', 'o'}, 'm', require'leap-ast'.leap, {silent = true})
set_keymap('n', 'zf', function()
  vim.cmd("normal! v")
  require'leap-ast'.leap()
  vim.cmd("normal! zf")
end, {silent = true, desc='manually fold lines based on treehopper'})
set_keymap('x', 'iu', ':lua require"treesitter-unit".select()<CR>')
set_keymap('x', 'au', ':lua require"treesitter-unit".select(true)<CR>')
set_keymap('o', 'iu', ':<C-U>lua require"treesitter-unit".select()<CR>')
set_keymap('o', 'au', ':<C-U>lua require"treesitter-unit".select(true)<CR>')


--[[ git settings ]]
-- <C-G><C-S> is used by telescope.builtin.git_status
-- vgit
local Vgit = require'vgit'
Vgit.setup {
  keymaps = {
    ['n <Up>'] = 'hunk_up',
    ['n <Down>'] = 'hunk_down',
    ['n <C-G><C-P>'] = 'buffer_hunk_preview',
    ['n <C-G><C-R>'] = 'buffer_hunk_reset',
  },
  settings = {
    live_blame = {
      enabled = false
    }
  }
}
vim.api.nvim_create_user_command('ToggleBlame', Vgit.toggle_live_blame, {})
for k, v in pairs(Vgit) do
  if type(v) == "function" then
    set_keymap('n', '<Plug>(vgit.' .. k .. ')', v)
  end
end
set_keymap('n', '<C-G>a', '<Cmd>up<CR><Plug>(vgit.buffer_stage)')
set_keymap('n', '<C-G><C-A>', '<Cmd>up<CR><Plug>(vgit.buffer_hunk_stage)')

-- fugitive
set_keymap('n', '<C-G><C-Space>', '<Cmd>Git commit<Space><CR>')

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
  local winid = vim.fn.win_getid()
  vim.cmd('ToggleTermSendCurrentLine')
  vim.api.nvim_set_current_win(winid)
end
set_keymap('n', '<Leader>j', _toggleterm_run, {desc = 'ToggleTermSendCurrentLine'})

-- toggleterm:lazygit
local lazygit = require'toggleterm.terminal'.Terminal:new {
  cmd = 'lazygit',
  hidden = true,
  direction = 'float'
}
set_keymap(
  'n', '<C-G><C-L>',
  function() lazygit:toggle() end,
  {desc = 'lazygit', silent = true}
)


--[[ fuzzyfinder settings ]]
-- telescope
local Telescope = require'telescope'
local TelescopeBuiltin = require'telescope.builtin'
local telescope_hook_cmd = {
  fern = "normal! i'fern-action ",
  ["gin-status"] = "normal! i'gin-action ",
}
local function telescope_keymaps()
    local ft = vim.api.nvim_buf_get_option(0,  "filetype")
    TelescopeBuiltin.keymaps({mode = vim.api.nvim_get_mode().mode})
    local cmd = telescope_hook_cmd[ft]
    if cmd then
      vim.cmd(cmd)
    end
end
Telescope.setup()
Telescope.load_extension('fzf')
for _, v in pairs {
  {'n', 'mb', 'buffers'},
  {'n', 'mc', 'commands'},
  {'n', 'mf', 'find_files'},
  {'n', 'mg', 'live_grep'},
  {'n', 'mh', 'help_tags'},
  {'n', '<C-G><C-S>', 'git_status'},
  {'n', 'mk', 'marks'},
  {'n', 'mm', 'keymaps', telescope_keymaps},
  {{'n', 'v', 'i'}, '<C-P>m', 'keymaps', telescope_keymaps},
  {'n', 'ml', 'git_files'},
  {'n', 'mr', 'registers'},
  {{'n', 'i'}, '<C-P>r', 'registers'},
  {'n', 'm.', 'resume'},
  {'n', 'mt', 'treesitter'},
  {'n', 'm/', 'current_buffer_fuzzy_find'},
  {'n', 'q;', 'command_history'},
  {'n', 'q:', 'command_history'},
  {'n', 'q/', 'search_history'},
} do
  set_keymap(v[1], v[2], v[4] or TelescopeBuiltin[v[3]], {desc = 'telescope ' .. v[3]})
end
for k, v in pairs(TelescopeBuiltin) do
  if type(v) == "function" then
    set_keymap('n', '<Plug>(telescope.' .. k .. ')', v)
  end
end


--[[ LSP settings ]]
-- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
require("mason").setup()
local LspSaga = require'lspsaga'
LspSaga.init_lsp_saga({
  code_action_lightbulb = { virtual_text = false, sign = false }
})
set_keymap('n', '<Leader>e', vim.diagnostic.open_float, {silent = true, desc = 'float diagnostic'})
set_keymap('n', '[d', vim.diagnostic.goto_prev, {silent = true, desc = 'previous diagnostic'})
set_keymap('n', ']d', vim.diagnostic.goto_next, {silent = true, desc = 'next diagnositc'})
set_keymap('n', '<Leader>q', vim.diagnostic.setloclist, {silent = true, desc = 'add buffer diagnositcs to the location list'})

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
  -- set_keymap('n', '<Leader>rn', require'lspsaga.rename'.lsp_rename, OPTS)
  set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', OPTS)
  set_keymap('n', '<Leader>ca', require'lspsaga.codeaction'.code_action, OPTS)
  -- set_keymap('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', OPTS)
  set_keymap('n', 'gr', TelescopeBuiltin.lsp_references, OPTS)
  -- set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', OPTS)
  set_keymap('n', '<Leader>lf', '<cmd>lua vim.lsp.buf.formatting()<CR>', OPTS)
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
  terraformls = { filetypes = { "terraform", "tf" } },
  sumneko_lua = {
    settings = {
      Lua = vim.env.LUA_RUNTIME and {
        workspace = {
          library = vim.api.nvim_get_runtime_file('', true),
        },
      } or {},
    },
  }, -- pacman -S lua-language-server
  gopls = {},
} do
  setup_lsp(lsp, config)
end

vim.api.nvim_create_augroup("terraform-custom", {})
vim.api.nvim_create_autocmd({"FileType"}, {
  group="terraform-custom",
  pattern = { "tf" },
  callback = function(_)
    vim.api.nvim_buf_set_option(0, "filetype", "terraform")
  end
})
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  group="terraform-custom",
  pattern = {"*.tf", "*.tfvars"},
  callback = vim.lsp.buf.formatting_sync,
})

--[[ autocompletion settings ]]
-- ddc
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/ddc.vim')

local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values

local function search_lines(lines, pat)
  local matches = {}
  for _, line in ipairs(lines) do
    if vim.fn.match(line, pat) ~= -1 then
      table.insert(matches, line)
    end
  end
  return matches
end

local function search_file(fname, pat)
  return search_lines(vim.fn.readfile(fname), pat)
end

local regex_emoji = '[' .. [[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF\U00002500-\U00002BEF\U00002702-\U000027B0\U00002702-\U000027B0\U0001f926-\U0001f937\U00010000-\U0010ffff\u2640-\u2642\u2600-\u2B55\u200d\u23cf\u23e9\u231a\ufe0f\u3030]] .. ']'

local prefix_emoji = function(bufnr, alt)
  bufnr = bufnr or 0
  alt = alt or {'.gitmessage'}
  local win = vim.api.nvim_get_current_win()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Test if emoji is required
  if vim.fn.match(lines[0], regex_emoji) ~= -1 then
    return
  end

  -- Search for candidates
  local emoji_lines = search_lines(lines, regex_emoji)
  for _, fname in ipairs(alt) do
    if #emoji_lines ~= 0 then
      break
    end
    if vim.fn.findfile(fname) ~= '' then
      emoji_lines = search_file(fname, regex_emoji)
    end
  end
  if #emoji_lines == 0 then
    return
  end

  -- Create temporary buffer and floating window to run telescope
  -- local tempbuf = vim.api.nvim_create_buf(false, true)
  -- vim.api.nvim_buf_set_lines(tempbuf, 0, -1, false, emoji_lines)
  -- local floating = vim.api.nvim_open_win(tempbuf, true, {
  --   relative="editor",
  --   width=1,
  --   height=1,
  --   row=0,
  --   col=0
  -- })

  -- find emoji
  pickers.new({}, {
    previewer = false,
    prompt_title = "colors",
    finder = finders.new_table {
      results = emoji_lines
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- actions.close:enhance{
      --   post = function()
      --     vim.api.nvim_win_close(floating, true)
      --     vim.api.nvim_buf_delete(tempbuf, {force=true})
      --   end
      -- }
      local _ = map
      actions.select_default:replace(
        function()
          actions.close(prompt_bufnr)
          vim.api.nvim_set_current_win(win)
          local selection = action_state.get_selected_entry()
          local emoji = vim.fn.matchstr(selection[1], regex_emoji)
          if (emoji ~= '') then
            vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, {emoji})
          end
        end
      )
      return true
    end
  }):find()
end

vim.api.nvim_create_user_command('EmojiPrefix', function() prefix_emoji() end, {})
set_keymap('', '<Plug>(emoji-prefix)', function() prefix_emoji() end)
set_keymap('n', 'me', '<Plug>(emoji-prefix)')
