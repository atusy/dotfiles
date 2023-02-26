local utils = require("atusy.utils")
local set_keymap, set_palette = utils.set_keymap, utils.set_palette

vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync" },
  callback = function()
    local lockfile = "~/.config/nvim/lazy-lock.json"
    os.execute("chezmoi add " .. lockfile)
  end,
})

local deps = {
  {
    "atusy/tsnode-marker.nvim",
    lazy = true,
    init = function()
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
              "class_definition",
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
      vim.api.nvim_create_autocmd("FileType", {
        group = utils.augroup,
        pattern = "markdown",
        callback = function(ctx)
          -- blank target requires capture group @tsodemarker
          -- dot_config/nvim/after/queries/markdown/highlights.scm
          require("tsnode-marker").set_automark(ctx.buf, {
            -- target = { "code_fence_content" },
            hl_group = "@illuminate",
          })
        end,
      })
    end,
  },
  -- basic dependencies
  "tpope/vim-repeat",
  "vim-denops/denops.vim",
  {
    "yuki-yano/denops-lazy.nvim",
    lazy = true,
    config = function()
      require("denops-lazy").setup()
    end,
  },
  { "kana/vim-submode", enabled = false },
  {
    "delphinus/cellwidths.nvim",
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
        0xe795, --  actually 2?
      }, ", ") .. "}")
    end,
  },

  -- utils
  { "dstein64/vim-startuptime", cmd = "StartupTime" },
  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    keys = { { "g", mode = "" } },
    config = function()
      require("Comment").setup({
        toggler = { line = "gcc", block = "gcb" },
        pre_hook = function()
          require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
        end,
      })
    end,
  },
  { "lambdalisue/vim-manpager", cmd = "Man" },
  { "lambdalisue/guise.vim" },
  {
    "lambdalisue/fern.vim",
    dependencies = { "lambdalisue/fern-renderer-nerdfont.vim", "lambdalisue/nerdfont.vim" },
    cmd = { "Fern" },
    init = function()
      set_palette("n", "Fern drawer", "<Cmd>Fern . -drawer -reveal=%<CR>")
    end,
    config = function()
      vim.g["fern#renderer"] = "nerdfont"
      vim.g["fern#renderer#nerdfont#indent_markers"] = 1
      vim.g["fern#window_selector_use_popup"] = 1
      local function fern_chowcho()
        local node = vim.api.nvim_exec(
          [[
          let helper = fern#helper#new()
          echo helper.sync.get_selected_nodes()[0]["_path"]
        ]],
          true
        )
        require("chowcho").run(function(n)
          vim.api.nvim_set_current_win(n)
          vim.cmd("edit " .. node)
        end)
      end

      local function init_fern()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        vim.opt_local.cursorline = true
        vim.opt_local.signcolumn = "auto"
        set_keymap("n", "S", "<C-W>p", { buffer = 0 })
        set_keymap("n", "s", "<Nop>", { buffer = 0 })
        set_keymap("n", " rn", "<Plug>(fern-action-rename)", { buffer = 0 }) -- like lsp rename
        set_keymap("n", "<CR>", "<Plug>(fern-action-open:select)", { buffer = 0, nowait = true })
        set_keymap("n", "<C-L>", "<Cmd>nohl<CR>", { buffer = 0 })
        set_keymap("n", "<Plug>(fern-action-open:chowcho)", fern_chowcho, { buffer = 0 })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fern",
        group = utils.augroup,
        callback = function()
          pcall(init_fern)
        end,
      })
    end,
  },
  { "segeljakt/vim-silicon", cmd = { "Silicon", "SiliconHighlight" } }, -- pacman -S silicon
  {
    "tyru/open-browser.vim",
    keys = {
      { "gx", "<Plug>(openbrowser-smart-search)", mode = { "n", "x" } },
      { "<2-LeftMouse>", "<Plug>(openbrowser-open)", mode = { "n" } },
    },
  },
  {
    "tpope/vim-characterize",
    keys = { "ga" },
  },

  -- ui
  {
    "xiyaowong/nvim-transparent", -- not so good with styler.nvim
    cmd = "TransparentToggle",
    config = function()
      require("transparent").setup({})
    end,
  },
  -- "MunifTanjim/nui.nvim",
  -- "rcarriga/nvim-notify",
  -- "folke/noice.nvim",
  -- "stevearc/stickybuf.nvim",

  -- windows and buffers
  {
    "echasnovski/mini.bufremove", -- instead of 'moll/vim-bbye',
    lazy = true,
    init = function()
      set_palette("n", "Bdelete", function()
        require("mini.bufremove").delete()
      end)
      set_palette("n", "Bwipeout", function()
        require("mini.bufremove").wipeout()
      end)
    end,
  },
  -- 'mhinz/vim-sayonara',
  -- { 'stevearc/stickybuf.nvim' },
  {
    "m00qek/baleia.nvim",
    lazy = true,
    init = function()
      local baleia
      set_palette("n", "parse ANSI escape sequences", function()
        baleia = baleia or require("baleia").setup()
        baleia.once(vim.api.nvim_get_current_buf())
      end)
    end,
  },
  {
    "tyru/capture.vim",
    cmd = "Capture",
    init = function()
      set_palette("n", "Capture", ":Capture ", { remap = true })
    end,
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    init = function()
      set_palette("n", "ZenMode", "<Cmd>ZenMode<CR>")
    end,
  },
  {
    "thinca/vim-qfreplace",
    cmd = "Qfreplace",
    init = function()
      set_palette("n", "Qfreplace", "<Cmd>Qfreplace<CR>")
    end,
  },

  -- better something
  {
    "lambdalisue/kensaku.vim",
    dependencies = { "vim-denops/denops.vim", "yuki-yano/denops-lazy.nvim" },
    lazy = true,
    config = function()
      require("denops-lazy").load("kensaku.vim")
    end,
  },
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = { "lambdalisue/kensaku.vim", "vim-denops/denops.vim", "yuki-yano/denops-lazy.nvim" },
    cmd = "FuzzyMotion",
    init = function()
      set_keymap("n", ";", "<Cmd>FuzzyMotion<CR>")
    end,
    config = function()
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
      require("denops-lazy").load("fuzzy-motion.vim")
    end,
  },
  {
    "haya14busa/vim-asterisk",
    keys = {
      { "*", "<Plug>(asterisk-z*)", mode = "n" },
      { "*", "<Plug>(asterisk-gz*)", mode = "x" },
    },
  },
  {
    "wsdjeg/vim-fetch", -- :e with linenumber
    lazy = false, -- some how event-based lazy loading won't work as expected
  },
  {
    "yuki-yano/denops-open-http.vim",
    dependencies = { "vim-denops/denops.vim" },
    -- event = 'CmdlineEnter',
    -- config = function()
    --   require('denops-lazy').load('denops-open-http.vim')
    -- end
  },
  "lambdalisue/readablefold.vim", -- or anuvyklack/pretty-fold.nvim
  { "jghauser/mkdir.nvim", event = { "VeryLazy", "CmdlineEnter" } }, -- :w with mkdir
  {
    "andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
    end,
  },
  {
    "Wansmer/treesj",
    lazy = true,
    init = function()
      -- treesj does not support visual mode, so leave the mode and use cursor as the node indicator
      set_palette("", "join lines based on AST", [[<C-\><C-N>:lua require('treesj').join()<CR>]])
      set_palette("", "split lines based on AST", [[<C-\><C-N>:lua require('treesj').split()<CR>]])
    end,
    config = function()
      require("treesj").setup({ use_default_keymaps = false })
    end,
  },
  {
    "monaqa/dial.nvim",
    lazy = true,
    init = function()
      set_keymap("n", "<C-A>", function()
        return require("dial.map").inc_normal()
      end, { expr = true })
      set_keymap("n", "<C-X>", function()
        return require("dial.map").dec_normal()
      end, { expr = true })
      set_keymap("x", "<C-A>", function()
        return require("dial.map").inc_visual()
      end, { expr = true })
      set_keymap("x", "<C-X>", function()
        return require("dial.map").dec_visual()
      end, { expr = true })
      set_keymap("x", "g<C-A>", function()
        return require("dial.map").inc_gvisual()
      end, { expr = true })
      set_keymap("x", "g<C-X>", function()
        return require("dial.map").dec_gvisual()
      end, { expr = true })
    end,
  },
  {
    "yuki-yano/highlight-undo.nvim",
    event = "User DenopsReady",
    cond = false,
    config = function()
      require("denops-lazy").load("highlight-undo.nvim")
      require("highlight-undo").setup({})
    end,
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "WinNew",
    dependencies = { "nvim-tree/nvim-web-devicons" },
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
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "fern" },
      })
    end,
  },
  -- use 'b0o/incline.nvim' -- TODO

  -- motion
  {
    "haya14busa/vim-edgemotion",
    keys = {
      { "<A-]>", "<Plug>(edgemotion-j)", mode = "" },
      { "<A-[>", "<Plug>(edgemotion-k)", mode = "" },
    },
  },
  {
    "phaazon/hop.nvim",
    lazy = true,
    init = function()
      local function hopper(direction, offset)
        return function()
          require("hop").hint_char1({
            direction = require("hop.hint").HintDirection[direction],
            current_line_only = true,
            hint_offset = offset == nil and 0 or offset,
          })
        end
      end

      set_keymap("", "f", hopper("AFTER_CURSOR"))
      set_keymap("", "F", hopper("BEFORE_CURSOR"))
      set_keymap("", "t", hopper("AFTER_CURSOR", -1))
      set_keymap("", "T", hopper("BEFORE_CURSOR", 1))
      set_keymap("n", "gn", function()
        require("hop").hint_patterns({}, vim.fn.getreg("/"))
      end)
    end,
    config = function()
      require("hop").setup()
    end,
  },
  {
    "ggandor/leap.nvim",
    lazy = true,
    config = function()
      -- LeapBackdrop highlight is defined at colorscheme.lua
      local function hi(_)
        require("leap").init_highlight(true)
        vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      end

      vim.api.nvim_create_autocmd("User", { pattern = "LeapEnter", group = utils.augroup, callback = hi })

      require("leap").setup({ safe_labels = {} })
    end,
  },
  {
    "ggandor/leap-ast.nvim", -- prefer nvim-treehopper
    dependencies = { "ggandor/leap.nvim" },
    lazy = true,
  },
  -- 'ggandor/flit.nvim',

  -- treesitter
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = true, -- will be loaded via Comment.nvim
    config = function()
      require("nvim-treesitter.configs").setup({
        context_commentstring = { enable = true, enable_autocmd = false },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
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
      local treesitterpath = utils.datapath .. "/treesitter"
      vim.opt.runtimepath:append(treesitterpath)
      require("nvim-treesitter.configs").setup({
        parser_install_dir = treesitterpath,
        ensure_installed = "all",
        highlight = {
          enable = true,
          disable = function(lang)
            local ok = pcall(function()
              vim.treesitter.get_query(lang, "highlights")
            end)
            return not ok
          end,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      })

      local register = vim.treesitter.language.register -- since Nvim 0.9
        or function(lang, ft)
          require("nvim-treesitter.parsers").filetype_to_parsername[ft] = lang
        end
      register("bash", "zsh")
      register("hcl", "tf")
      register("diff", "gin-diff")

      local function hi()
        vim.api.nvim_set_hl(0, "@illuminate", { bg = "#383D47" })
      end

      hi()
      vim.api.nvim_create_autocmd("ColorScheme", { group = utils.augroup, callback = hi })
    end,
  },
  -- 'nvim-treesitter/playground', -- vim.treesitter.show_tree would be enough
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    keys = { "[", "]", " " },
    event = "ModeChanged",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = false, -- prefer mini.ai
            lookahead = true,
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "around function" },
              ["if"] = { query = "@function.inner", desc = "inside function" },
              ["ac"] = { query = "@class.outer", desc = "around class" },
              ["ic"] = { query = "@class.inner", desc = "inside class" },
            },
            selection_modes = {
              ["@parameter.outer"] = "v", -- charwise
              ["@function.outer"] = "V", -- linewise
              ["@class.outer"] = "<c-v>", -- blockwise
            },
            include_surrounding_whitespace = false,
          },
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
    "nvim-treesitter/nvim-treesitter-refactor",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = true,
    init = function()
      set_keymap("n", " rn", function()
        require("nvim-treesitter-refactor.smart_rename").smart_rename(0)
      end)
    end,
  },
  -- 'haringsrob/nvim_context_vt',
  {
    "David-Kunz/treesitter-unit",
    lazy = true,
    enabled = false, -- because viuiu will not expand the region
    init = function()
      set_keymap({ "o", "x" }, "iu", ':<C-U>lua require"treesitter-unit".select()<CR>')
      set_keymap({ "o", "x" }, "au", ':<C-U>lua require"treesitter-unit".select(true)<CR>')
    end,
  },
  {
    "romgrk/nvim-treesitter-context",
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
    "mfussenegger/nvim-treehopper",
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
      set_keymap("n", "zf", function()
        hi()
        require("tsht").nodes({ ignore_injections = false })
        vim.cmd("normal! Vzf")
      end, { silent = true })
    end,
  },
  {
    "RRethy/nvim-treesitter-endwise",
    ft = { "ruby", "lua", "sh", "bash", "zsh", "vim" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({ endwise = { enable = true } })
    end,
  },

  -- autopairs
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    config = function()
      require("mini.pairs").setup({})
    end,
  },

  -- terminal
  {
    "chomosuke/term-edit.nvim",
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
    "akinsho/toggleterm.nvim",
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
    "notomo/cmdbuf.nvim",
    -- dependencies = { 'nvim-telescope/telescope.nvim' }, -- not required on config
    config = function()
      set_keymap("n", "q:", function()
        require("cmdbuf").split_open(vim.o.cmdwinheight)
        local ok, telescope = pcall(require, "telescope.builtin")
        if ok then
          vim.schedule(function()
            vim.cmd("e!")
            telescope.current_buffer_fuzzy_find()
          end)
        end
      end)
      set_keymap("c", "<C-F>", function()
        local opt = { line = vim.fn.getcmdline(), column = vim.fn.getcmdpos() }
        local open = require("cmdbuf").split_open
        vim.schedule(function()
          open(vim.o.cmdwinheight, opt)
        end)
        return [[<C-\><C-N>]]
      end, { expr = true })
    end,
  },

  -- filetype specific
  { "mattn/vim-goimports", ft = "go" },
  {
    "barrett-ruth/import-cost.nvim",
    ft = { "javascript", "typescript", "typescriptreact" },
    build = "sh install.sh yarn",
    config = function()
      require("import-cost").setup()
    end,
  },
  {
    "phelipetls/jsonpath.nvim",
    ft = "json",
    config = function()
      set_palette("n", "clipboard json path", function()
        local path = require("jsonpath").get()
        vim.fn.setreg("+", path)
        vim.notify("jsonpath: " .. path)
      end, { desc = "clipboard json path" })
    end,
  },
  { "itchyny/vim-qfedit", ft = "qf" },
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
  },
  {
    "norcalli/nvim-terminal.lua",
    ft = "terminal",
    config = function()
      require("terminal").setup()
    end,
  },
}

return deps
