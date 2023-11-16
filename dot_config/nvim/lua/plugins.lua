local utils = require("atusy.utils")
local set_keymap = vim.keymap.set

vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean" },
  callback = function()
    local lockfile = "~/.config/nvim/lazy-lock.json"
    vim.system({ "chezmoi", "add", lockfile })
  end,
})

local deps = {
  -- basic dependencies
  "https://github.com/tpope/vim-repeat",
  "https://github.com/vim-denops/denops.vim",
  {
    "https://github.com/yuki-yano/denops-lazy.nvim",
    lazy = true,
    config = function()
      require("denops-lazy").setup()
    end,
  },
  {
    "https://github.com/delphinus/cellwidths.nvim",
    event = { "BufReadPost", "ModeChanged" },
    config = function()
      -- ga
      -- https://en.wikipedia.org/wiki/List_of_Unicode_characters
      require("cellwidths").setup({ name = "default" })
      vim.cmd.CellWidthsAdd("{ 0xe000, 0xf8ff, 2 }") -- 私用領域（外字領域）
      vim.cmd.CellWidthsAdd("{ 0x2423, 0x2423, 2 }") -- ␣
      vim.cmd.CellWidthsDelete("{" .. table.concat({
        0x2190,
        0x2191,
        0x2192,
        0x2193, -- ←↑↓→
        0x25b2,
        0x25bc, -- ▼▲
        0x25cf, -- ●
        0x2713, -- ✓
        0x279c, -- ➜
        0x2717, -- ✗
        0xe727, --  actually 2?
      }, ", ") .. "}")
    end,
  },

  -- utils
  { "https://github.com/dstein64/vim-startuptime", cmd = "StartupTime" },
  {
    "https://github.com/numToStr/Comment.nvim",
    dependencies = { "https://github.com/JoosepAlviste/nvim-ts-context-commentstring" },
    lazy = true,
    init = function()
      set_keymap("n", "gcc", [[<Cmd>lua require("Comment.api").toggle.linewise.current()<CR>]])
      set_keymap("x", "gc", [[<Esc><Cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>]])
      set_keymap("x", "gb", [[<Esc><Cmd>lua require("Comment.api").toggle.blockwise(vim.fn.visualmode())<CR>]])
    end,
    config = function()
      require("Comment").setup({
        mappings = false,
        pre_hook = function()
          require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
        end,
      })
    end,
  },
  { "https://github.com/lambdalisue/guise.vim", dependencies = { "https://github.com/vim-denops/denops.vim" } },
  { "https://github.com/lambdalisue/askpass.vim", dependencis = { "https://github.com/vim-denops/denops.vim" } },
  { "https://github.com/segeljakt/vim-silicon", cmd = { "Silicon", "SiliconHighlight" } }, -- pacman -S silicon
  {
    "https://github.com/tyru/open-browser.vim",
    keys = {
      { "gx", "<Plug>(openbrowser-smart-search)", mode = { "n", "x" } },
      { "<2-LeftMouse>", "<Plug>(openbrowser-open)", mode = { "n" } },
    },
  },
  { "https://github.com/tpope/vim-characterize", keys = { "ga" } },
  { "https://github.com/thinca/vim-partedit", cmd = "Partedit" },

  -- ui
  {
    "https://github.com/lukas-reineke/indent-blankline.nvim",
    lazy = true,
    init = function()
      set_keymap("n", "<Bar>", function()
        -- without count, toggle indent_blankline. Otherwise fallback to native <Bar>-like behavior
        if vim.v.count == 0 then
          -- must be scheduled to suppress textlock related errors
          require("ibl").update({ enabled = not require("ibl.config").get_config(-1).enabled })
        else
          vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], vim.v.count - 1 })
        end
      end)
    end,
    config = function()
      local function set_hl()
        vim.api.nvim_set_hl(0, "IBLIndent1", { fg = "#E06C75", nocombine = true })
        vim.api.nvim_set_hl(0, "IBLIndent2", { fg = "#E5C07B", nocombine = true })
        vim.api.nvim_set_hl(0, "IBLIndent3", { fg = "#98C379", nocombine = true })
        vim.api.nvim_set_hl(0, "IBLIndent4", { fg = "#56B6C2", nocombine = true })
        vim.api.nvim_set_hl(0, "IBLIndent5", { fg = "#61AFEF", nocombine = true })
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("atusy.ibl", {}),
        callback = set_hl,
      })
      set_hl()
      require("ibl").setup({
        enabled = false,
        indent = {
          highlight = { "IBLIndent1", "IBLIndent2", "IBLIndent3", "IBLIndent4", "IBLIndent5" },
        },
        scope = { enabled = false },
      })
    end,
  },
  {
    "https://github.com/xiyaowong/nvim-transparent", -- not so good with styler.nvim
    cmd = "TransparentToggle",
    config = function()
      require("transparent").setup({})
    end,
  },
  -- "https://github.com/MunifTanjim/nui.nvim",
  -- "https://github.com/rcarriga/nvim-notify",
  -- "https://github.com/folke/noice.nvim",
  -- "https://github.com/stevearc/stickybuf.nvim",

  -- windows and buffers
  {
    "https://github.com/echasnovski/mini.bufremove",
    lazy = true,
    config = function()
      require("atusy.keymap.palette").add_item("n", "Bdelete", [[<Cmd>lua require("mini.bufremove").delete()<CR>]])
      require("atusy.keymap.palette").add_item("n", "Bwipeout", [[<Cmd>lua require("mini.bufremove").wipeout()<CR>]])
    end,
  },
  -- 'mhinz/vim-sayonara',
  -- { 'stevearc/stickybuf.nvim' },
  {
    "https://github.com/m00qek/baleia.nvim",
    lazy = true,
    config = function()
      require("atusy.keymap.palette").add_item("n", "parse ANSI escape sequences", function()
        require("baleia").setup().once(vim.api.nvim_get_current_buf())
      end)
    end,
  },
  {
    "https://github.com/tyru/capture.vim",
    cmd = "Capture",
    init = function()
      vim.keymap.set("c", "<c-x><c-c>", function()
        local t = vim.fn.getcmdtype()
        if t ~= ":" then
          return
        end
        local l = vim.fn.getcmdline()
        vim.schedule(function()
          vim.cmd("Capture " .. l)
        end)
        return "<c-c>"
      end, { expr = true })
    end,
  },
  { "https://github.com/folke/zen-mode.nvim", cmd = "ZenMode" },
  { "https://github.com/thinca/vim-qfreplace", cmd = "Qfreplace" },

  -- better something
  {
    "https://github.com/chrisbra/Recover.vim",
    lazy = false,
  },
  {
    "https://github.com/lambdalisue/kensaku.vim",
    dependencies = { "https://github.com/vim-denops/denops.vim" },
    lazy = false,
    config = function(p)
      if p.lazy then
        require("denops-lazy").load("kensaku.vim")
      end
    end,
  },
  {
    "https://github.com/wsdjeg/vim-fetch", -- :e with linenumber
    lazy = false, -- some how event-based lazy loading won't work as expected
  },
  { "https://github.com/lambdalisue/readablefold.vim", lazy = true }, -- or anuvyklack/pretty-fold.nvim, but disabled in preference of atusy.fold.foldtext
  { "https://github.com/jghauser/mkdir.nvim", event = { "VeryLazy", "CmdlineEnter" } }, -- :w with mkdir
  {
    "https://github.com/andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
      -- disable treesitter integration as it becomes very slow somehow...
      require("nvim-treesitter.configs").setup({
        matchup = {
          enable = true, -- mandatory, false will disable the whole extension
          -- disable = { "c", "ruby" }, -- optional, list of language that will be disabled
          -- [options]
          disable_virtual_text = true,
          include_match_words = true,
          enable_quotes = true,
        },
      })
    end,
  },
  {
    "https://github.com/Wansmer/treesj",
    lazy = true,
    config = function()
      require("treesj").setup({ use_default_keymaps = false })
      -- treesj does not support visual mode, so leave the mode and use cursor as the node indicator
      require("atusy.keymap.palette").add_item(
        "",
        "join lines based on AST",
        [[<C-\><C-N>:lua require('treesj').join()<CR>]]
      )
      require("atusy.keymap.palette").add_item(
        "",
        "split lines based on AST",
        [[<C-\><C-N>:lua require('treesj').split()<CR>]]
      )
    end,
  },
  {
    "https://github.com/monaqa/dial.nvim",
    lazy = true,
    init = function()
      vim.keymap.set("n", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "normal")<CR>]])
      vim.keymap.set("n", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "normal")<CR>]])
      vim.keymap.set("n", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gnormal")<CR>]])
      vim.keymap.set("n", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gnormal")<CR>]])
      vim.keymap.set("v", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "visual")<CR>]])
      vim.keymap.set("v", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "visual")<CR>]])
      vim.keymap.set("v", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gvisual")<CR>]])
      vim.keymap.set("v", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gvisual")<CR>]])
    end,
  },

  -- statusline
  {
    "https://github.com/nvim-lualine/lualine.nvim",
    event = "WinNew",
    dependencies = { "https://github.com/nvim-tree/nvim-web-devicons" },
    init = function()
      vim.opt.laststatus = 0
    end,
    config = function()
      vim.opt.laststatus = 2
      require("lualine").setup({
        options = { theme = "moonfly", component_separators = "" },
        sections = {
          lualine_a = {
            {
              "mode",
              fmt = function(x)
                return x == "TERMINAL" and x or ""
              end,
            },
          },
          lualine_b = { { "filetype", icon_only = true }, { "filename", path = 1 } },
          lualine_c = {},
          lualine_x = {},
          lualine_y = { { "location" } },
          lualine_z = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = { { "filetype", icon_only = true }, { "filename", path = 1 } },
          lualine_c = {},
          lualine_x = {},
          lualine_y = { { "location" } },
          lualine_z = {},
        },
        extensions = {},
      })
    end,
  },
  -- use 'b0o/incline.nvim' -- TODO

  -- motion
  {
    "https://github.com/haya14busa/vim-edgemotion",
    keys = {
      { "<A-]>", "<Plug>(edgemotion-j)", mode = "" },
      { "<A-[>", "<Plug>(edgemotion-k)", mode = "" },
    },
  },
  {
    "https://github.com/ggandor/leap.nvim",
    lazy = true,
    config = function()
      -- LeapBackdrop highlight is defined at colorscheme.lua
      local function hi(_)
        require("leap").init_highlight(true)
        vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      end

      vim.api.nvim_create_autocmd("User", { pattern = "LeapEnter", group = utils.augroup, callback = hi })

      require("leap").setup({
        safe_labels = { "s" },
        special_keys = {
          repeat_search = "<enter>",
          next_phase_one_target = "<enter>",
          next_target = { "<enter>", ";" },
          prev_target = { "<tab>", "," },
          next_group = "<tab>",
          prev_group = "<s-tab>",
          multi_accept = "<enter>",
          multi_revert = "<backspace>",
        },
      })
    end,
  },
  {
    "https://github.com/rapan931/lasterisk.nvim",
    lazy = true,
    init = function()
      set_keymap("n", "*", [[<Cmd>lua require("lasterisk").search()<CR>]])
      set_keymap("n", "g*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR>]])
      set_keymap("x", "*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR><C-\><C-N>]])
    end,
  },

  -- treesitter
  {
    "https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = { "https://github.com/nvim-treesitter/nvim-treesitter" },
    lazy = true, -- will be loaded via Comment.nvim
    config = function()
      require("nvim-treesitter.configs").setup({
        context_commentstring = { enable = true, enable_autocmd = false },
      })
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      local function is_inner(x, y)
        if x[1] < y[1] then
          return false
        end
        if (x[1] == y[1]) and (x[2] < y[2]) then
          return false
        end
        if x[3] > y[3] then
          return false
        end
        if (x[3] == y[3]) and (x[4] > y[4]) then
          return false
        end
        return true
      end

      local function is_same(x, y)
        for i, v in pairs(x) do
          if v ~= y[i] then
            return false
          end
        end
        return true
      end

      local function get_node_range(node)
        return { vim.treesitter.get_node_range(node) }
      end

      local function get_curpos()
        local p = vim.api.nvim_win_get_cursor(0)
        return p[1] - 1, p[2] + 1
      end

      local function get_vrange()
        local r1, c1 = get_curpos()
        vim.cmd("normal! o")
        local r2, c2 = get_curpos()
        vim.cmd("normal! o")
        if (r1 == r2) and (c1 == c2) then
          return { r1, c1, r2, c2 }
        end
        if (r1 < r2) or ((r1 == r2) and (c1 < c2)) then
          return { r1, c1 - 1, r2, c2 }
        end
        return { r2, c2 - 1, r1, c1 }
      end

      set_keymap("x", "v", function()
        local ts_utils = require("nvim-treesitter.ts_utils")
        local vrange = get_vrange()
        local node = ts_utils.get_node_at_cursor()
        local nrange = get_node_range(node)

        local parent
        while true do
          if is_inner(vrange, nrange) and not is_same(vrange, nrange) then
            break
          end
          parent = node:parent()
          if parent == nil then
            break
          end
          node = parent
          nrange = get_node_range(node)
        end
        ts_utils.update_selection(0, node)
      end, { desc = "node incremental selection" })
    end,
    config = function()
      -- install directory of treesitter parsers
      local treesitterpath = utils.datapath .. "/treesitter"
      vim.opt.runtimepath:append(treesitterpath)

      -- add non-official parsers
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      local parser_uri = vim.uv.os_homedir() .. "/ghq/github.com/atusy/tree-sitter-uri"
      if not vim.uv.fs_stat(parser_uri) then
        parser_uri = "https://github.com/atusy/tree-sitter-uri"
      end
      parser_config.uri = {
        install_info = {
          url = parser_uri,
          files = { "src/parser.c" },
          generate_requires_npm = false, -- if stand-alone parser without npm dependencies
          requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
        },
        filetype = "uri", -- if filetype does not match the parser name
      }

      -- setup
      require("nvim-treesitter.configs").setup({
        parser_install_dir = treesitterpath,
        ensure_installed = "all",
        highlight = {
          enable = true,
          disable = function(lang)
            local ok = pcall(vim.treesitter.query.get, lang, "highlights")
            return not ok
          end,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      })

      -- register parsers to some other languages
      vim.treesitter.language.register("bash", "zsh")
      vim.treesitter.language.register("bash", "sh")
      vim.treesitter.language.register("hcl", "tf")
      vim.treesitter.language.register("diff", "gin-diff")

      -- custom highlights
      local function hi()
        vim.api.nvim_set_hl(0, "@illuminate", { bg = "#383D47" })
      end

      hi()
      vim.api.nvim_create_autocmd("ColorScheme", { group = utils.augroup, callback = hi })
    end,
  },
  -- 'nvim-treesitter/playground', -- vim.treesitter.show_tree would be enough
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    keys = { "[", "]", " " },
    event = "ModeChanged",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          -- select = {}, -- done via mini.ai
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = { query = "@class.outer", desc = "Next class start" },
              --
              -- You can use regex matching and/or pass a list in a "query" key to group multiple queires.
              ["]o"] = "@loop.*",
              -- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
              --
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              -- ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
              -- ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = false,
            border = "none",
            floating_preview_opts = {},
            peek_definition_code = {
              ["<leader>df"] = "@function.outer",
              ["<leader>dF"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-refactor",
    dependencies = { "https://github.com/nvim-treesitter/nvim-treesitter" },
    lazy = true,
    init = function()
      set_keymap("n", " rn", function()
        require("nvim-treesitter-refactor.smart_rename").smart_rename(0)
      end)
    end,
  },
  -- 'haringsrob/nvim_context_vt',
  {
    "https://github.com/romgrk/nvim-treesitter-context",
    event = "BufReadPre",
    config = function()
      require("treesitter-context").setup({
        enable = true,
        patterns = {
          css = { "media_statement", "rule_set" },
          scss = { "media_statement", "rule_set" },
          rmd = { "section" },
        },
      })
    end,
  },
  {
    "https://github.com/mfussenegger/nvim-treehopper",
    lazy = true,
    init = function()
      local function hi()
        vim.api.nvim_set_hl(0, "TSNodeUnmatched", { link = "Comment" })
        vim.api.nvim_set_hl(0, "TSNodeKey", { link = "IncSearch" })
      end
      local function tsht()
        hi()
        return ":<C-U>lua require('tsht').nodes({ignore_injections = false})<CR>"
      end
      set_keymap("o", "m", tsht, { expr = true, silent = true })
      set_keymap("x", "m", tsht, { expr = true, silent = true })
      local function zc(n)
        -- with count, use zc
        if (n or vim.v.count) > 0 then
          vim.cmd("normal! " .. vim.v.count .. "zc")
          return
        end

        -- without count, use tsht to select a resion to close or create one
        -- make sure foldexpr is updated by zx
        hi()
        require("tsht").nodes({ ignore_injections = false })
        local ok = pcall(function()
          vim.cmd("normal! Vzxzc")
        end)
        if not ok then
          vim.cmd("normal! zxgvzf")
        end
      end
      set_keymap("n", "zc", zc)
      set_keymap("n", "zf", function()
        -- zc if foldmethod is expr
        if vim.api.nvim_get_option_value("foldmethod", {}) == "expr" then
          zc(vim.v.count)
          return
        end

        -- create fold
        hi()
        require("tsht").nodes({ ignore_injections = false })
        vim.cmd("normal! Vzf")
      end, { silent = true })
    end,
  },
  {
    "https://github.com/RRethy/nvim-treesitter-endwise",
    ft = { "ruby", "lua", "sh", "bash", "zsh", "vim" },
    dependencies = { "https://github.com/nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({ endwise = { enable = true } })
    end,
  },
  {
    "https://github.com/atusy/tsnode-marker.nvim",
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = utils.augroup,
        pattern = "markdown",
        callback = function(ctx)
          -- blank target requires capture group @tsnodemarker
          -- dot_config/nvim/after/queries/markdown/highlights.scm
          require("tsnode-marker").set_automark(ctx.buf, {
            -- target = { "code_fence_content" },
            hl_group = "@illuminate",
          })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = utils.augroup,
        pattern = { "lua", "python", "go" },
        callback = function(ctx)
          local function is_def(n)
            return vim.tbl_contains({
              "func_literal",
              "function_declaration",
              "function_definition",
              "method_declaration",
              "method_definition",
            }, n:type())
          end
          require("tsnode-marker").set_automark(ctx.buf, {
            target = function(_, node)
              if not is_def(node) then
                return false
              end
              local parent = node:parent()
              while parent do
                if is_def(parent) then
                  return true
                end
                parent = parent:parent()
              end
              return false
            end,
            hl_group = "@illuminate",
          })
        end,
      })
    end,
    config = function()
      -- vim.api.nvim_set_hl(0, "@tsnodemarker", { link = "@illuminate" })
    end,
  },

  -- autopairs
  {
    "https://github.com/hrsh7th/nvim-insx",
    event = "InsertEnter",
    config = function()
      require("insx.preset.standard").setup()
    end,
  },

  -- terminal
  {
    "https://github.com/chomosuke/term-edit.nvim",
    event = "TermEnter",
    config = function()
      require("term-edit").setup({
        prompt_end = "[»#$] ",
        mapping = {
          n = { s = false, S = false },
        },
      })
    end,
  },
  {
    "https://github.com/akinsho/toggleterm.nvim",
    keys = { "<C-T>", { " <CR>", mode = { "n", "x" } } },
    cmd = { "ToggleTermSendCurrentLine", "ToggleTermSendVisualSelection" },
    config = function()
      set_keymap("n", " <CR>", ":ToggleTermSendCurrentLine<CR>")
      set_keymap("x", " <CR>", ":ToggleTermSendVisualSelection<CR>gv<Esc>")
      require("toggleterm").setup({
        open_mapping = "<C-T>",
        insert_mappings = false,
        shade_terminals = false,
        shading_factor = 0,
      })
    end,
  },

  -- cmdwin
  {
    "https://github.com/notomo/cmdbuf.nvim",
    lazy = true,
    init = function()
      vim.keymap.set("c", "<C-F>", function()
        require("cmdbuf").split_open(vim.o.cmdwinheight, { line = vim.fn.getcmdline(), column = vim.fn.getcmdpos() })
        vim.api.nvim_feedkeys(vim.keycode("<C-C>"), "n", true)
      end)
    end,
    config = function()
      vim.api.nvim_create_autocmd({ "User" }, {
        group = utils.augroup,
        pattern = { "CmdbufNew" },
        callback = function(args)
          vim.bo.bufhidden = "wipe"
          local max_count = 10
          local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
          vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, vim.list_slice(lines, #lines - max_count))
        end,
      })
    end,
  },

  -- filetype specific
  { "https://github.com/mattn/vim-goimports", ft = "go" },
  {
    "https://github.com/barrett-ruth/import-cost.nvim",
    ft = { "javascript", "typescript", "typescriptreact" },
    build = "sh install.sh yarn",
    config = function()
      require("import-cost").setup()
    end,
  },
  {
    "https://github.com/phelipetls/jsonpath.nvim",
    ft = "json",
    config = function()
      add_palette("n", "clipboard json path", function()
        local path = require("jsonpath").get()
        vim.fn.setreg("+", path)
        vim.notify("jsonpath: " .. path)
      end, { desc = "clipboard json path" })
    end,
  },
  { "https://github.com/itchyny/vim-qfedit", ft = "qf" },
  {
    "https://github.com/kevinhwang91/nvim-bqf",
    ft = "qf",
  },
}

return deps
