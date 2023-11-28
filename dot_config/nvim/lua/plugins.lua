local utils = require("atusy.utils")

vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean" },
  callback = function()
    vim.system({ "chezmoi", "add", require("lazy.core.config").options.lockfile })
  end,
})

return {
  -- basic dependencies
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
  {
    "https://github.com/numToStr/Comment.nvim",
    dependencies = { "https://github.com/JoosepAlviste/nvim-ts-context-commentstring" },
    lazy = true,
    init = function()
      vim.keymap.set("n", "gcc", [[<Cmd>lua require("Comment.api").toggle.linewise.current()<CR>]])
      vim.keymap.set("x", "gc", [[<Esc><Cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>]])
      vim.keymap.set("x", "gb", [[<Esc><Cmd>lua require("Comment.api").toggle.blockwise(vim.fn.visualmode())<CR>]])
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
      vim.keymap.set("n", "<Bar>", function()
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
        indent = { highlight = { "IBLIndent1", "IBLIndent2", "IBLIndent3", "IBLIndent4", "IBLIndent5" } },
        scope = { enabled = false },
      })
    end,
  },
  { "https://github.com/xiyaowong/nvim-transparent", lazy = true }, -- watch, but prefer atusy.highlight to support styler.nvim

  -- windows and buffers
  {
    "https://github.com/echasnovski/mini.bufremove",
    lazy = true,
    config = function()
      require("atusy.keymap.palette").add_item("n", "Bdelete", [[<Cmd>lua require("mini.bufremove").delete()<CR>]])
      require("atusy.keymap.palette").add_item("n", "Bwipeout", [[<Cmd>lua require("mini.bufremove").wipeout()<CR>]])
    end,
  },
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
        matchup = { enable = true, disable_virtual_text = true, include_match_words = true, enable_quotes = true },
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

  -- motion
  {
    "https://github.com/haya14busa/vim-edgemotion",
    keys = {
      { "<A-]>", "<Plug>(edgemotion-j)", mode = "" },
      { "<A-[>", "<Plug>(edgemotion-k)", mode = "" },
    },
  },
  {
    "https://github.com/rapan931/lasterisk.nvim",
    lazy = true,
    init = function()
      vim.keymap.set("n", "*", [[<Cmd>lua require("lasterisk").search()<CR>]])
      vim.keymap.set("n", "g*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR>]])
      vim.keymap.set("x", "*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR><C-\><C-N>]])
    end,
  },

  -- treesitter
  {
    "https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true, -- will be loaded via Comment.nvim
    config = function()
      require("ts_context_commentstring").setup({ enable_autocmd = false })
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.keymap.set("x", "v", "<Plug>(ts-node-inc)", {})
      vim.keymap.set("x", " v", "<Plug>(ts-node-desc)", {})
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
      parser_config.unifieddiff = {
        install_info = {
          url = "https://github.com/monaqa/tree-sitter-unifieddiff",
          -- url = "~/ghq/github.com/monaqa/tree-sitter-unifieddiff",
          files = { "src/parser.c", "src/scanner.c" },
        },
        filetype = "diff", -- if filetype does not agrees with parser name
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
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = false,
            node_incremental = "<Plug>(ts-node-inc)",
            scope_incremental = false,
            node_decremental = "<Plug>(ts-node-desc)",
          },
        },
      })

      -- register parsers to some other languages
      vim.treesitter.language.register("bash", "zsh")
      vim.treesitter.language.register("bash", "sh")
      vim.treesitter.language.register("hcl", "tf")
      vim.treesitter.language.register("unifieddiff", "gin-diff")

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
    lazy = true,
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          -- select = {}, -- done via mini.ai
          move = { enable = false },
          lsp_interop = { enable = false },
        },
      })
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-refactor",
    dependencies = { "https://github.com/nvim-treesitter/nvim-treesitter" },
    lazy = true,
    init = function()
      vim.keymap.set("n", " rn", [[<Cmd>lua require("nvim-treesitter-refactor.smart_rename").smart_rename(0)<CR>]], {})
    end,
  },
  -- 'haringsrob/nvim_context_vt',
  {
    "https://github.com/romgrk/nvim-treesitter-context",
    event = "CursorHold",
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
      vim.keymap.set(
        { "x", "o" },
        "<Plug>(tsht)",
        ":<C-U>lua require('tsht').nodes({ignore_injections = false})<CR>",
        { silent = true }
      )
      vim.keymap.set({ "x", "o" }, "m", "<Plug>(tsht)")
      vim.keymap.set("n", "zf", "zfV<Plug>(tsht)")
    end,
    config = function()
      vim.api.nvim_set_hl(0, "TSNodeUnmatched", { link = "Comment" })
      vim.api.nvim_set_hl(0, "TSNodeKey", { link = "IncSearch" })
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
    dev = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        desc = "High-level reproduction of highlights by delta via GinDiff",
        group = utils.augroup,
        pattern = "gin-diff",
        callback = function(ctx)
          local nm = vim.api.nvim_buf_get_name(ctx.buf)
          if not nm:match("processor=delta") then
            return
          end
          vim.api.nvim_set_hl(0, "DeltaLineAdded", { fg = "#FFFFFF", bg = "#002800" })
          vim.api.nvim_set_hl(0, "DeltaLineDeleted", { fg = "#FFFFFF", bg = "#3f0001" })
          require("tsnode-marker").set_automark(ctx.buf, {
            target = { "line_deleted", "line_added" },
            hl_group = function(_, node)
              local t = node:type()
              return ({
                line_added = "DeltaLineAdded",
                line_deleted = "DeltaLineDeleted",
              })[t] or "None"
            end,
            priority = 101, -- to override treesitter highlighting
          })
        end,
      })
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
        pattern = { "python", "go" },
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
        mapping = { n = { s = false, S = false } },
      })
    end,
  },
  {
    "https://github.com/akinsho/toggleterm.nvim",
    keys = { "<C-T>", { " <CR>", mode = { "n", "x" } } },
    cmd = { "ToggleTermSendCurrentLine", "ToggleTermSendVisualSelection" },
    config = function()
      vim.keymap.set("n", " <CR>", ":ToggleTermSendCurrentLine<CR>")
      vim.keymap.set("x", " <CR>", ":ToggleTermSendVisualSelection<CR>gv<Esc>")
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
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = utils.augroup,
        pattern = "json",
        callback = function(ctx)
          require("atusy.keymap.palette").add_item("n", "clipboard: json path", function()
            local path = require("jsonpath").get()
            vim.fn.setreg("+", path)
            vim.notify("jsonpath: " .. path)
          end, { buffer = ctx.buf })
        end,
      })
    end,
  },
  { "https://github.com/itchyny/vim-qfedit", ft = "qf" },
  {
    "https://github.com/kevinhwang91/nvim-bqf",
    ft = "qf",
  },
}
