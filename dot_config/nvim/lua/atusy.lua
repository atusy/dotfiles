--[[ TODO
https://github.com/sumneko/lua-language-server/wiki/Annotations
https://qiita.com/delphinus/items/fb905e452b2de72f1a0f
https://zenn.dev/nnsnico/articles/customize-lsp-handler

## Plugin

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
--]]

-- [[ helpers ]]
local utils = require('utils').require('utils') -- force reloading self
utils.setup()
local set_keymap = utils.set_keymap

--[[ options ]]
vim.opt.exrc = true

-- signcolumn
vim.opt.signcolumn = 'yes'

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

--[[ commands ]]
vim.api.nvim_create_user_command('W', 'write !sudo tee % >/dev/null', {})

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
set_keymap('n', '<ESC><ESC>', '<Cmd>nohlsearch<CR>')
set_keymap({ 'n', 'v' }, 'x', '"_x')
set_keymap({ 'n', 'v' }, 'X', '"_X')
set_keymap('n', 'gf', 'gF')
set_keymap('n', 'gff', 'gF')
set_keymap('n', 'gfh', '<cmd>leftabove vertical wincmd F<cr>')
set_keymap('n', 'gfj', '<cmd>below horizontal wincmd F<cr>')
set_keymap('n', 'gfk', '<cmd>above horizontal wincmd F<cr>')
set_keymap('n', 'gfl', '<cmd>rightbelow vertical wincmd F<cr>')
set_keymap({ 'n', 'v' }, 'gy', '"+y')
set_keymap({ 'n', 'v' }, 'gY', '"+Y')
set_keymap('c', '<C-A>', '<Home>')
set_keymap('t', '<C-W>', [[<C-\><C-N><C-W>]])
set_keymap({ 'n', 'v', 'i', 't', 'c' }, [[<C-\><C-\>]], [[<C-\><C-N>]])

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

set_keymap('n', 'g<C-O>', function() return jump(false) end, { fav = false, expr = true })
set_keymap('n', 'g<C-I>', function() return jump(true) end, { fav = false, expr = true })

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
set_keymap('n', '<Plug>(C-S)<C-S>', ':source<CR>', { fav = false }) -- Save and Source
set_keymap('n', '<Plug>(C-S)<C-S>', function()
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local bufext = bufname:gsub('.*%.', '')
  if bufext ~= 'vim' and bufext ~= 'lua' then
    vim.notify('Cannot source: ' .. bufname, vim.log.levels.ERROR)
    return
  end
  vim.ui.input(
    { prompt = 'Press enter to source %' },
    function(input) if input == '' then vim.cmd('source %') end end
  )
end, { fav = false }) -- Save and Source

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

-- <Plug> to be invoked by Telescope keymap
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
              vim.schedule(function() pcall(vim.api.nvim_set_current_win, parent) end)
            end
          })
        end)
      end,
      nested = true,
    }
  )
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
    -- require('config.scorpeon'),
  }
end)()
local DATAPATH = vim.fn.stdpath("data")
local deps = {
  -- basic dependencies
  'tpope/vim-repeat',
  'vim-denops/denops.vim',
  'kana/vim-submode',
  {
    'delphinus/cellwidths.nvim',
    config = function()
      require("cellwidths").setup { name = "default" }
      vim.cmd.CellWidthsDelete("{" .. table.concat({
        0x2190, 0x2191, 0x2192, 0x2193, -- ←↑↓→
        0x2713, -- ✓
      }, ", ") .. "}")
    end
  },

  -- utils
  { 'dstein64/vim-startuptime', cmd = 'StartupTime' },
  {
    'numToStr/Comment.nvim',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      require('Comment').setup {
        toggler = { line = 'gcc', block = 'gcb' },
        pre_hook = function() require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook() end,
      }
    end,
  },
  { 'lambdalisue/guise.vim', event = "VeryLazy" },
  {
    'lambdalisue/fern.vim',
    dependencies = { 'lambdalisue/fern-renderer-nerdfont.vim', 'lambdalisue/nerdfont.vim' },
    cmd = { 'Fern' },
    init = function()
      set_keymap('n', 'S', '<Cmd>Fern . -drawer -reveal=%<CR>')
    end,
    config = function()
      vim.g["fern#renderer"] = "nerdfont"
      vim.g["fern#renderer#nerdfont#indent_markers"] = 1
      vim.g["fern#window_selector_use_popup"] = 1
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
        set_keymap('n', 'S', '<C-W>p', { buffer = 0 })
        set_keymap('n', 's', '<Nop>', { buffer = 0 })
        set_keymap('n', ' rn', '<Plug>(fern-action-rename)', { buffer = 0 }) -- like lsp rename
        set_keymap('n', '<CR>', '<Plug>(fern-action-open:select)', { buffer = 0, nowait = true })
        set_keymap('n', '<Plug>(fern-action-open:chowcho)', fern_chowcho, { buffer = 0 })
      end

      vim.api.nvim_create_autocmd("FileType",
        {
          pattern = "fern",
          group = utils.augroup,
          callback = function() pcall(init_fern) end
        }
      )
    end
  },
  { 'segeljakt/vim-silicon', cmd = { 'Silicon', 'SiliconHighlight' } }, -- pacman -S silicon
  {
    'tyru/open-browser.vim',
    keys = { '<Plug>(openbrowser-smart-search)' },
    init = function()
      set_keymap({ 'n', 'v' }, 'gx', '<Plug>(openbrowser-smart-search)')
    end
  },

  -- ui
  -- "MunifTanjim/nui.nvim",
  -- "rcarriga/nvim-notify",
  -- "folke/noice.nvim",
  -- "stevearc/stickybuf.nvim",

  -- windows and buffers
  { 'moll/vim-bbye', cmd = { 'Bdelete', 'Bwipeout' } },
  -- 'mhinz/vim-sayonara',
  -- { 'stevearc/stickybuf.nvim' },
  {
    'm00qek/baleia.nvim',
    config = function()
      local baleia
      set_keymap(
        'n', '<Plug>(parse-ansi)',
        function()
          baleia = baleia or require('baleia').setup()
          baleia.once(vim.api.nvim_get_current_buf())
        end,
        { desc = 'Parse ANSI escape sequences in current buffer' }
      )
    end
  },
  { 'tyru/capture.vim', cmd = 'Capture' },
  { 'folke/zen-mode.nvim', cmd = 'ZenMode' },
  { 'thinca/vim-qfreplace', cmd = 'Qfreplace' },

  -- better something
  {
    'haya14busa/vim-asterisk',
    keys = { '<Plug>(asterisk-z*)', '<Plug>(asterisk-gz*)' },
    init = function()
      set_keymap('n', '*', '<Plug>(asterisk-z*)')
      set_keymap('v', '*', '<Plug>(asterisk-gz*)')
    end
  },
  { 'wsdjeg/vim-fetch', event = { 'CmdlineEnter' } }, -- :e with linenumber
  'lambdalisue/readablefold.vim',
  { 'jghauser/mkdir.nvim', event = { 'VeryLazy', 'CmdlineEnter' } }, -- :w with mkdir
  -- anuvyklack/pretty-fold.nvim

  -- statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require 'lualine'.setup {
        options = { theme = 'moonfly', component_separators = '', },
        sections = {
          lualine_a = {},
          lualine_b = { { 'filetype', icon_only = true }, { 'filename', path = 1 } },
          lualine_c = {},
          lualine_x = {},
          lualine_y = { { 'location' } },
          lualine_z = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = { { 'filetype', icon_only = true }, { 'filename', path = 1 } },
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        -- tabline = {
        --   lualine_a = {},
        --   -- lualine_b = {
        --   --   function()
        --   --     if vim.opt_local.filetype:get() == "json" then
        --   --       local has_jsonpath, jsonpath = pcall(require, 'jsonpath')
        --   --       if has_jsonpath then
        --   --         return jsonpath.get()
        --   --       end
        --   --     end
        --   --     local has_navic, nav = pcall(require, 'nvim-navic')
        --   --     if has_navic and nav.is_available() then
        --   --       return nav.get_location()
        --   --     end
        --   --     return ''
        --   --   end
        --   -- },
        --   lualine_c = {},
        --   lualine_x = {},
        --   lualine_y = {},
        --   lualine_z = {},
        -- },
        extensions = { 'fern', 'toggleterm' }
      }
    end
  },
  -- use 'b0o/incline.nvim' -- TODO

  -- motion
  {
    'haya14busa/vim-edgemotion',
    keys = { '<Plug>(edgemotion-j)', '<Plug>(edgemotion-k)' },
    init = function()
      set_keymap('', '<A-]>', '<Plug>(edgemotion-j)', {})
      set_keymap('', '<A-[>', '<Plug>(edgemotion-k)', {})
    end
  },
  {
    'phaazon/hop.nvim',
    config = function()
      local function _setup_hop() require('hop').setup() end

      local function hopper(direction, offset)
        return function()
          _setup_hop = _setup_hop() or function() end
          require('hop').hint_char1({
            direction = require 'hop.hint'.HintDirection[direction],
            current_line_only = true,
            hint_offset = offset == nil and 0 or offset,
          })
        end
      end

      set_keymap('', 'f', hopper('AFTER_CURSOR'), { desc = 'Hop after' })
      set_keymap('', 'F', hopper('BEFORE_CURSOR'), { desc = 'Hop before' })
      set_keymap('', 't', hopper('AFTER_CURSOR', -1), { desc = 'Hop after' })
      set_keymap('', 'T', hopper('BEFORE_CURSOR', 1), { desc = 'Hop before' })
      set_keymap(
        'n', 'gn',
        function()
          _setup_hop = _setup_hop() or function() end
          require('hop').hint_patterns({}, vim.fn.getreg('/'))
        end,
        { desc = 'Hop previous search pattern' }
      )
    end
  },
  {
    'ggandor/leap.nvim',
    config = function()
      -- LeapBackdrop highlight is defined at colorscheme.lua
      local function _setup_leap() require('leap').setup({ safe_labels = {} }) end

      set_keymap(
        { 'n', 'v' }, ';',
        function()
          _setup_leap = _setup_leap() or function() end
          require('leap').leap({ target_windows = { vim.api.nvim_get_current_win() } })
        end
      )
    end
  },
  {
    'ggandor/leap-ast.nvim',
    dependencies = { 'ggandor/leap.nvim' },
    init = function()
      vim.keymap.set({ 'v', 'o' }, '<Plug>(leap-ast)', function() require 'leap-ast'.leap() end, { silent = true })
    end
  },
  -- 'ggandor/flit.nvim',
  -- 'yuki-yano/fuzzy-motion.vim',

  -- treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    pin = true,
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    init = function()
      set_keymap(
        'n', '<Plug>(treesitter-show-tree)',
        function() vim.treesitter.show_tree() end,
        { desc = 'treesitter show tree' }
      )
    end,
    config = function()
      local treesitterpath = DATAPATH .. "/treesitter"
      vim.opt.runtimepath:append(treesitterpath)
      require 'nvim-treesitter.configs'.setup {
        parser_install_dir = treesitterpath,
        ensure_installed = 'all',
        context_commentstring = { enable = true, enable_autocmd = false },
        highlight = {
          enable = true,
          disable = function(lang)
            local ok = pcall(function() vim.treesitter.get_query(lang, 'highlights') end)
            return not ok
          end,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      }
      local ft_to_parser = require 'nvim-treesitter.parsers'.filetype_to_parsername
      ft_to_parser.zsh = 'bash'
      ft_to_parser.tf = 'hcl'
    end
  },
  -- 'nvim-treesitter/playground', -- vim.treesitter.show_tree would be enough
  {
    'nvim-treesitter/nvim-treesitter-refactor',
    init = function()
      set_keymap(
        'n', '<Leader>rn', -- lsp may overridde the feature if renameProvider is available
        function() require 'nvim-treesitter-refactor.smart_rename'.smart_rename(0) end,
        { desc = 'treesitter rename' }
      )
    end
  },
  -- 'haringsrob/nvim_context_vt',
  {
    'romgrk/nvim-treesitter-context',
    config = function()
      require 'treesitter-context'.setup({
        enable = true,
        patterns = {
          css = { 'media_statement', 'rule_set', },
          scss = { 'media_statement', 'rule_set', },
          rmd = { 'section' }
        },
      })
    end
  },
  {
    'mfussenegger/nvim-treehopper',
    init = function()
      set_keymap(
        'n', 'zf',
        function()
          local ok = pcall(require 'tsht'.nodes)
          if not ok then
            vim.cmd('normal! v')
            require 'leap-ast'.leap()
          end
          vim.cmd('normal! zf')
        end,
        { silent = true, desc = 'manually fold lines based on treehopper' }
      )
      set_keymap('o', 'm', function()
        local ok = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
        return ok and ":<C-U>lua require('tsht').nodes()<CR>" or [[<Plug>(leap-ast)]]
      end, { expr = true, silent = true })
      set_keymap('x', 'm', function()
        local ok = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
        return ok and ":lua require('tsht').nodes()<CR>" or [[<Plug>(leap-ast)]]
      end, { silent = true, expr = true })
    end
  },
  'JoosepAlviste/nvim-ts-context-commentstring',

  -- text object
  {
    'machakann/vim-sandwich',
    config = function()
      vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])
      local recipes = vim.fn.deepcopy(vim.g['operator#sandwich#default_recipes'])
      table.insert(recipes, {
        buns = { '(', ')' },
        kind = { 'add' },
        action = { 'add' },
        cursor = 'head',
        command = { 'startinsert' },
        input = { vim.api.nvim_replace_termcodes("<C-F>", true, false, true) },
      })
      vim.g['operator#sandwich#recipes'] = recipes

      set_keymap(
        'n', 's(', '<Plug>(operator-sandwich-add-query1st)<C-F>',
        { desc = 'sandwich query with () and start insert before (' }
      )
      set_keymap(
        { 'x', 'v' }, 's(', '<Plug>(operator-sandwich-add)<C-F>',
        { desc = 'sandwich query with () and start insert before (' }
      )
    end
  },

  -- terminal
  {
    'akinsho/toggleterm.nvim',
    keys = { '<Plug>(toggleterm-toggle)' },
    cmd = { 'ToggleTermSendCurrentLine', 'ToggleTermSendVisualSelection' },
    init = function()
      set_keymap({ 'n', 't' }, '<C-T>', '<Plug>(toggleterm-toggle)')
      set_keymap('n', '<Leader>j', ':ToggleTermSendCurrentLine<CR>j',
        { desc = 'send the line to toggle term and go to next line' })
      set_keymap('v', '<Leader>j', ":ToggleTermSendVisualSelection<CR>gv<Esc>",
        { desc = 'send the selection to toggle term while keeping the cursor position' })
    end,
    config = function()
      require 'toggleterm'.setup {
        open_mapping = '<Plug>(toggleterm-toggle)',
        insert_mappings = false,
        shade_terminals = false,
        shading_factor = 0,
      }
    end
  },

  -- cmdwin
  {
    'notomo/cmdbuf.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      set_keymap("n", "q:", function()
        require("cmdbuf").split_open(vim.o.cmdwinheight)
        local ok, telescope = pcall(require, 'telescope.builtin')
        if ok then vim.schedule(telescope.current_buffer_fuzzy_find) end
      end)
      set_keymap("c", "<C-F>", function()
        local opt = { line = vim.fn.getcmdline(), column = vim.fn.getcmdpos() }
        local open = require('cmdbuf').split_open
        vim.schedule(function() open(vim.o.cmdwinheight, opt) end)
        return [[<C-\><C-N>]]
      end, { expr = true })
    end
  },

  -- filetype specific
  { 'mattn/vim-goimports', ft = 'go' },
  { 'phelipetls/jsonpath.nvim', ft = 'json' },
  { 'itchyny/vim-qfedit', ft = 'qf' },
}
for _, config in pairs(configurations) do
  for _, dep in pairs(config.deps) do
    table.insert(deps, dep)
  end
end

--[[ lazy.nvim ]]
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
require('lazy').setup(deps)

for _, config in ipairs(configurations) do
  config.setup()
end

vim.api.nvim_create_autocmd('CmdlineEnter', {
  group = utils.augroup,
  once = true,
  callback = function()
    local telescomp = "/home/atusy/ghq/github.com/atusy/telescomp"
    if vim.fn.isdirectory(telescomp) == 0 then return end
    vim.opt.runtimepath:append(telescomp)
    local cmdline_builtin = utils.require('telescomp.cmdline.builtin')
    set_keymap('c', '<C-X><C-B>', cmdline_builtin.git_branches)
    set_keymap('c', '<C-X><C-F>', cmdline_builtin.find_files)
    set_keymap('c', '<C-X><C-M>', cmdline_builtin.builtin)
    set_keymap('c', '<C-X><C-D>', cmdline_builtin.cmdline)
    set_keymap('c', '<C-D>', cmdline_builtin.cmdline)
    set_keymap('n', '<Plug>(telescomp-colon)', ':', { remap = true })
    set_keymap('n', '<Plug>(telescomp-slash)', '/', { remap = true })
    set_keymap('n', '<Plug>(telescomp-question)', '?', { remap = true })
  end
})
