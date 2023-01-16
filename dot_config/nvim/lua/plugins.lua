local utils = require('utils')
local set_keymap = utils.set_keymap

vim.api.nvim_create_autocmd('User', {
  pattern = { 'LazyInstall', 'LazyUpdate', 'LazySync' },
  callback = function()
    local lockfile = '~/.config/nvim/lazy-lock.json'
    os.execute('chezmoi add ' .. lockfile)
  end
})

local deps = {
  -- basic dependencies
  'tpope/vim-repeat',
  'vim-denops/denops.vim',
  { 'kana/vim-submode', enabled = false },
  {
    'delphinus/cellwidths.nvim',
    event = { 'BufReadPost', 'ModeChanged' },
    config = function()
      -- ga
      -- https://en.wikipedia.org/wiki/List_of_Unicode_characters
      require("cellwidths").setup { name = "default" }
      vim.cmd.CellWidthsAdd("{ 0xe000, 0xf8ff, 2 }") -- 私用領域（外字領域）
      vim.cmd.CellWidthsDelete("{" .. table.concat({
        0x2190, 0x2191, 0x2192, 0x2193, -- ←↑↓→
        0x25b2, 0x25bc, -- ▼▲
        0x25cf, -- ●
        0x2713, -- ✓
        0x279c, -- ➜
        0x2717, -- ✗
        0xe727, -- 
      }, ", ") .. "}")
    end
  },

  -- utils
  { 'dstein64/vim-startuptime', cmd = 'StartupTime' },
  {
    'numToStr/Comment.nvim',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    keys = { { 'g', mode = '' } },
    config = function()
      require('Comment').setup {
        toggler = { line = 'gcc', block = 'gcb' },
        pre_hook = function() require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook() end,
      }
    end,
  },
  { 'lambdalisue/vim-manpager', cmd = "Man" },
  { 'lambdalisue/guise.vim', event = { "TermOpen" } },
  {
    'lambdalisue/fern.vim',
    dependencies = { 'lambdalisue/fern-renderer-nerdfont.vim', 'lambdalisue/nerdfont.vim' },
    cmd = { 'Fern' },
    init = function()
      set_keymap('n', '<Plug>(Fern)', '<Cmd>Fern . -drawer -reveal=%<CR>', { fav = false })
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
        set_keymap('n', '<C-L>', '<Cmd>nohl<CR>', { buffer = 0 })
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
    keys = { { 'gx', '<Plug>(openbrowser-smart-search)', mode = { 'n', 'v' } } },
  },

  -- ui
  {
    "xiyaowong/nvim-transparent", -- not so good with styler.nvim
    cmd = "TransparentToggle",
    config = function() require('transparent').setup({}) end,
  },
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
    keys = {
      { '*', '<Plug>(asterisk-z*)', mode = 'n' },
      { '*', '<Plug>(asterisk-gz*)', mode = 'v' },
    },
  },
  {
    'wsdjeg/vim-fetch', -- :e with linenumber
    lazy = false, -- some how event-based lazy loading won't work as expected
  },
  {
    'yuki-yano/denops-open-http.vim',
    event = 'User DenopsReady'
  },
  'lambdalisue/readablefold.vim', -- or anuvyklack/pretty-fold.nvim
  { 'jghauser/mkdir.nvim', event = { 'VeryLazy', 'CmdlineEnter' } }, -- :w with mkdir
  {
    "andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
    end,
  },
  {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    init = function()
      -- treesj does not support visual mode, so leave the mode and use cursor as the node indicator
      set_keymap('', '<Plug>(TSJJoin)', '<C-\\><C-N>:TSJJoin<CR>', { desc = 'join lines based on AST' })
      set_keymap('', '<Plug>(TSJSplit)', '<C-\\><C-N>:TSJSplit<CR>', { desc = 'split lines based on AST' })
    end,
    config = function() require("treesj").setup({ use_default_keymaps = false }) end,
  },
  {
    'monaqa/dial.nvim',
    lazy = true,
    init = function()
      set_keymap("n", "<C-A>", function() return require("dial.map").inc_normal() end, { expr = true })
      set_keymap("n", "<C-X>", function() return require("dial.map").dec_normal() end, { expr = true })
      set_keymap("v", "<C-A>", function() return require("dial.map").inc_visual() end, { expr = true })
      set_keymap("v", "<C-X>", function() return require("dial.map").dec_visual() end, { expr = true })
      set_keymap("v", "g<C-A>", function() return require("dial.map").inc_gvisual() end, { expr = true })
      set_keymap("v", "g<C-X>", function() return require("dial.map").dec_gvisual() end, { expr = true })
    end
  },

  -- statusline
  {
    'nvim-lualine/lualine.nvim',
    event = 'WinNew',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    init = function()
      vim.opt.laststatus = 0
    end,
    config = function()
      vim.opt.laststatus = 2
      require 'lualine'.setup {
        options = { theme = 'moonfly', component_separators = '', },
        sections = {
          lualine_a = { { 'mode', fmt = function(x) return x == 'TERMINAL' and x or '' end } },
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
        extensions = { 'fern' }
      }
    end
  },
  -- use 'b0o/incline.nvim' -- TODO

  -- motion
  {
    'haya14busa/vim-edgemotion',
    keys = {
      { '<A-]>', '<Plug>(edgemotion-j)', mode = '' },
      { '<A-[>', '<Plug>(edgemotion-k)', mode = '' },
    },
  },
  {
    'phaazon/hop.nvim',
    lazy = true,
    init = function()
      local function hopper(direction, offset)
        return function()
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
        function() require('hop').hint_patterns({}, vim.fn.getreg('/')) end,
        { desc = 'Hop previous search pattern' }
      )
    end,
    config = function() require('hop').setup() end
  },
  {
    'ggandor/leap.nvim',
    lazy = true,
    init = function()
      set_keymap(
        { 'n', 'v' }, ';',
        function()
          require('leap').leap({ target_windows = { vim.api.nvim_get_current_win() } })
        end
      )
    end,
    config = function()
      -- LeapBackdrop highlight is defined at colorscheme.lua
      local function hi(_)
        require('leap').init_highlight(true)
        vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
      end

      vim.api.nvim_create_autocmd(
        "User", { pattern = 'LeapEnter', group = utils.augroup, callback = hi }
      )

      require('leap').setup({ safe_labels = {} })
    end
  },
  {
    'ggandor/leap-ast.nvim',
    dependencies = { 'ggandor/leap.nvim' },
    lazy = true,
    init = function()
      vim.keymap.set({ 'x', 'o' }, '<Plug>(leap-ast)', function() require 'leap-ast'.leap() end, { silent = true })
    end
  },
  -- 'ggandor/flit.nvim',
  -- 'yuki-yano/fuzzy-motion.vim',

  -- treesitter
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    lazy = true, -- will be loaded via Comment.nvim
    config = function()
      require 'nvim-treesitter.configs'.setup {
        context_commentstring = { enable = true, enable_autocmd = false },
      }
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    init = function()
      local function is_inner(x, y)
        if x[1] < y[1] then return false end
        if (x[1] == y[1]) and (x[2] < y[2]) then return false end
        if (x[3] > y[3]) then return false end
        if (x[3] == y[3]) and (x[4] > y[4]) then return false end
        return true
      end

      local function is_same(x, y)
        for i, v in pairs(x) do
          if v ~= y[i] then return false end
        end
        return true
      end

      local function get_node_range(node)
        local a, b, c, d = require('nvim-treesitter.ts_utils').get_node_range(node)
        return { a, b, c, d }
      end

      local function get_curpos()
        local p = vim.api.nvim_win_get_cursor(0)
        return p[1] - 1, p[2] + 1
      end

      local function get_vrange()
        local r1, c1 = get_curpos()
        vim.cmd('normal! o')
        local r2, c2 = get_curpos()
        vim.cmd('normal! o')
        if (r1 == r2) and (c1 == c2) then
          return { r1, c1, r2, c2 }
        end
        if (r1 < r2) or ((r1 == r2) and (c1 < c2)) then
          return { r1, c1 - 1, r2, c2 }
        end
        return { r2, c2 - 1, r1, c1 }
      end

      set_keymap('x', 'v',
        function()
          local ts_utils = require('nvim-treesitter.ts_utils')
          local vrange = get_vrange()
          local node = ts_utils.get_node_at_cursor()
          local nrange = get_node_range(node)

          local parent
          while true do
            if is_inner(vrange, nrange) and not is_same(vrange, nrange) then break end
            parent = node:parent()
            if parent == nil then break end
            node = parent
            nrange = get_node_range(node)
          end
          ts_utils.update_selection(0, node)
        end,
        { desc = 'node incremental selection' }
      )
      set_keymap(
        'n', '<Plug>(treesitter-show-tree)',
        function() vim.treesitter.show_tree() end,
        { desc = 'treesitter show tree' }
      )
    end,
    config = function()
      local treesitterpath = utils.datapath .. "/treesitter"
      vim.opt.runtimepath:append(treesitterpath)
      require 'nvim-treesitter.configs'.setup {
        parser_install_dir = treesitterpath,
        ensure_installed = 'all',
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

      local function hi()
        -- require('atusy.ts-highlight').setup()
        vim.api.nvim_set_hl(0, "@illuminate", { bg = "#383D47" })
      end

      hi()
      vim.api.nvim_create_autocmd('ColorScheme', { group = utils.augroup, callback = hi })
    end
  },
  -- 'nvim-treesitter/playground', -- vim.treesitter.show_tree would be enough
  {
    'nvim-treesitter/nvim-treesitter-refactor',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    lazy = true,
    init = function()
      set_keymap('n', ' rn', function() require 'nvim-treesitter-refactor.smart_rename'.smart_rename(0) end)
    end
  },
  -- 'haringsrob/nvim_context_vt',
  {
    'romgrk/nvim-treesitter-context',
    event = "BufReadPre",
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
    lazy = true,
    init = function()
      local function with_tsht()
        -- tsht fails if filetype differs from parser's language
        local ok = pcall(vim.treesitter.get_parser, 0)
        if not ok then return false end

        -- tsht does not support injection
        -- injected language could be detected by vim.inspect_pos().treesitter
        local cursor = vim.api.nvim_win_get_cursor(0)
        local function f(ignore)
          return { vim.treesitter.get_node_at_pos(0, cursor[1], cursor[2], { ignore_injections = ignore }):range() }
        end

        local range_original = f(true)
        local range_injection = f(false)
        for i, v in pairs(range_original) do
          if range_injection[i] ~= v then
            return false
          end
        end

        -- otherwise, set highlight and return true
        vim.api.nvim_set_hl(0, 'TSNodeUnmatched', { link = 'Comment', default = true })
        vim.api.nvim_set_hl(0, 'TSNodeKey', { link = 'IncSearch', default = true })
        return true
      end

      set_keymap('o', 'm', function()
        return with_tsht() and ":<C-U>lua require('tsht').nodes()<CR>" or [[<Plug>(leap-ast)]]
      end, { expr = true, silent = true })
      set_keymap('x', 'm', function()
        return with_tsht() and ":lua require('tsht').nodes()<CR>" or [[<Plug>(leap-ast)]]
      end, { silent = true, expr = true })
      set_keymap(
        'n', 'zf',
        function()
          if with_tsht() then
            require 'tsht'.nodes()
          else
            vim.cmd('normal! v')
            require 'leap-ast'.leap()
          end
          vim.cmd('normal! Vzf')
        end,
        { silent = true, desc = 'manually fold lines based on treehopper' }
      )
    end,
  },
  {
    'RRethy/nvim-treesitter-endwise',
    filetype = { 'ruby', 'lua', 'sh', 'bash', 'zsh', 'vim' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter.configs').setup({ endwise = { enable = true } })
    end,
  },

  -- text object
  {
    'machakann/vim-sandwich',
    keys = { { 's', mode = '' }, },
    config = function()
      vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])
      local recipes = vim.fn.deepcopy(vim.g['operator#sandwich#default_recipes'])
      table.insert(recipes, {
        buns = { '(', ')' },
        kind = { 'add' },
        action = { 'add' },
        cursor = 'head',
        cmd = { 'startinsert' },
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
    keys = { '<C-T>', { ' <CR>', mode = { 'n', 'x' } } },
    cmd = { 'ToggleTermSendCurrentLine', 'ToggleTermSendVisualSelection' },
    config = function()
      set_keymap('n', ' <CR>', ':ToggleTermSendCurrentLine<CR>j',
        { desc = 'send the line to toggle term and go to next line', fav = false })
      set_keymap('x', ' <CR>', ":ToggleTermSendVisualSelection<CR>gv<Esc>",
        { desc = 'send the selection to toggle term while keeping the cursor position', fav = false })
      require 'toggleterm'.setup {
        open_mapping = '<C-T>',
        insert_mappings = false,
        shade_terminals = false,
        shading_factor = 0,
      }
    end
  },

  -- cmdwin
  {
    'notomo/cmdbuf.nvim',
    -- dependencies = { 'nvim-telescope/telescope.nvim' }, -- not required on config
    config = function()
      set_keymap("n", "q:", function()
        require("cmdbuf").split_open(vim.o.cmdwinheight)
        local ok, telescope = pcall(require, 'telescope.builtin')
        if ok then
          vim.schedule(function()
            vim.cmd("e!")
            telescope.current_buffer_fuzzy_find()
          end)
        end
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
  {
    'barrett-ruth/import-cost.nvim',
    ft = { 'javascript', 'typescript', 'typescriptreact' },
    build = 'sh install.sh yarn',
    config = function()
      require('import-cost').setup()
    end
  },
  {
    'phelipetls/jsonpath.nvim',
    ft = 'json',
    config = function()
      set_keymap(
        'n', '<Plug>(clipboard-json-path)',
        function()
          local path = require "jsonpath".get()
          vim.fn.setreg('+', path)
          vim.notify('jsonpath: ' .. path)
        end, { desc = 'clipboard json path' }
      )
    end
  },
  { 'itchyny/vim-qfedit', ft = 'qf' },
  {
    "norcalli/nvim-terminal.lua",
    ft = "terminal",
    config = function()
      require("terminal").setup()
    end,
  },
}

return deps
