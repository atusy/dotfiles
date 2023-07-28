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
    lazy = true,
    init = function()
      set_keymap("n", "gcc", function()
        require("Comment.api").toggle.linewise.current()
      end)
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
        local node = vim.api.nvim_exec2(
          [[
          let helper = fern#helper#new()
          echo helper.sync.get_selected_nodes()[0]["_path"]
        ]],
          { output = true }
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
  {
    "thinca/vim-partedit",
    cmd = "Partedit",
  },

  -- ui
  {
    "lukas-reineke/indent-blankline.nvim",
    lazy = true,
    init = function()
      set_keymap("n", "<Bar>", function()
        -- without count, toggle indent_blankline
        if vim.v.count == 0 then
          -- must be scheduled to suppress textlock related errors
          require("indent_blankline.commands").toggle(true)
          return
        end

        -- with count, fallback to native <Bar>-like behavior
        vim.api.nvim_win_set_cursor(0, {
          vim.api.nvim_win_get_cursor(0)[1],
          vim.v.count - 1,
        })
      end)
      set_palette("n", "toggle indent blankline", function()
        require("indent_blankline.commands").toggle(true)
      end)
    end,
    config = function()
      vim.g.indent_blankline_char_priority = 3 -- should be higher than tsnode-marker's priority
      vim.g.indent_blankline_enabled = false
      vim.api.nvim_set_hl(0, "IndentBlanklineIndent1", { fg = "#E06C75", nocombine = true })
      vim.api.nvim_set_hl(0, "IndentBlanklineIndent2", { fg = "#E5C07B", nocombine = true })
      vim.api.nvim_set_hl(0, "IndentBlanklineIndent3", { fg = "#98C379", nocombine = true })
      vim.api.nvim_set_hl(0, "IndentBlanklineIndent4", { fg = "#56B6C2", nocombine = true })
      vim.api.nvim_set_hl(0, "IndentBlanklineIndent5", { fg = "#61AFEF", nocombine = true })
      require("indent_blankline").setup({
        show_current_context = true,
        show_current_context_start = true,
        char_highlight_list = {
          "IndentBlanklineIndent1",
          "IndentBlanklineIndent2",
          "IndentBlanklineIndent3",
          "IndentBlanklineIndent4",
          "IndentBlanklineIndent5",
        },
      })
    end,
  },
  {
    "xiyaowong/nvim-transparent", -- not so good with styler.nvim
    cmd = "TransparentToggle",
    config = function()
      require("transparent").setup({})
    end,
  },
  {
    "stevearc/oil.nvim",
    cond = false,
    init = function(p)
      if p.cond == false then
        return
      end
      set_keymap("n", "S", function()
        require("oil").open()
      end)
      set_keymap("n", "SS", function()
        require("oil").open()
      end)
    end,
    config = function()
      local oil = require("oil")
      oil.setup({
        use_default_keymaps = false,
        keymaps = {
          ["!"] = "actions.toggle_hidden",
          ["g?"] = "actions.show_help",
          ["S"] = function()
            require("oil.actions").close.callback()
          end,
          ["H"] = "actions.open_cwd",
          ["K"] = function()
            print(vim.fs.joinpath(oil.get_current_dir(), oil.get_cursor_entry().name))
          end,
          ["<CR>"] = "actions.select",
          ["<C-p>"] = "actions.preview",
          ["<C-l>"] = "actions.refresh",
          ["<Left>"] = "actions.parent",
          ["<Right>"] = "actions.select_vsplit",
          ["<Down>"] = "actions.select_split",
          ["<Up>"] = "actions.select_tab",
        },
      })
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
    "chrisbra/Recover.vim",
    lazy = false,
  },
  {
    "lambdalisue/kensaku.vim",
    dependencies = { "vim-denops/denops.vim", "yuki-yano/denops-lazy.nvim" },
    lazy = false,
    config = function()
      -- require("denops-lazy").load("kensaku.vim")
    end,
  },
  {
    "yuki-yano/fuzzy-motion.vim",
    cond = false,
    dependencies = { "lambdalisue/kensaku.vim", "vim-denops/denops.vim", "yuki-yano/denops-lazy.nvim" },
    cmd = "FuzzyMotion",
    init = function(p)
      if not p.cond then
        return
      end
      set_keymap({ "n", "x" }, ";", "<Cmd>FuzzyMotion<CR>")
    end,
    config = function()
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
      require("denops-lazy").load("fuzzy-motion.vim")
    end,
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
  {
    "tversteeg/registers.nvim",
    cond = false,
    config = function()
      require("registers").setup()
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
    "ggandor/leap.nvim",
    lazy = true,
    config = function()
      -- LeapBackdrop highlight is defined at colorscheme.lua
      local function hi(_)
        require("leap").init_highlight(true)
        vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      end

      vim.api.nvim_create_autocmd("User", { pattern = "LeapEnter", group = utils.augroup, callback = hi })

      require("leap").setup({
        safe_labels = {},
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
    "ggandor/leap-ast.nvim", -- prefer nvim-treehopper
    dependencies = { "ggandor/leap.nvim" },
    lazy = true,
  },
  -- 'ggandor/flit.nvim',
  {
    "atusy/leap-wide.nvim",
    lazy = true,
  },
  {
    "rapan931/lasterisk.nvim",
    lazy = true,
  },
  {
    "atusy/leap-search.nvim",
    lazy = true,
    dependencies = { "rapan931/lasterisk.nvim", "RRethy/vim-illuminate" },
    init = function()
      local function motion(offset, backward, inclusive_op)
        local pat = vim.fn.getcharstr()
        require("leap-search").leap(pat, {
          engines = {
            { name = "string.find", ignorecase = false, plain = true, nlines = 1 },
            {
              -- wrap kensaku.query to avoid ignorecase matches on alphabetic letters
              fn = function(s, ...)
                local query = require("leap-search.engine.kensaku.query").search(s, ...)
                if string.match(s, "^[A-Z]$") then
                  query = string.gsub(query, [[^(\m\%%%(%[)]] .. s .. string.lower(s), "%1")
                end
                return query
              end,
              nlines = 1,
            },
          },
          prefix_label = false,
        }, {
          backward = backward,
          offset = offset,
          inclusive_op = inclusive_op,
        })
      end

      set_keymap("o", "f", function()
        motion(1, false, true)
      end)
      set_keymap("o", "F", function()
        motion(0, true, true)
      end)
      set_keymap("o", "t", function()
        motion(0, false, true)
      end)
      set_keymap("o", "T", function()
        motion(1, true, true)
      end)
      set_keymap({ "n", "x" }, "f", function()
        motion(0, false)
      end)
      set_keymap({ "n", "x" }, "F", function()
        motion(0, true)
      end)
      set_keymap({ "n", "x" }, "t", function()
        motion(-1, false)
      end)
      set_keymap({ "n", "x" }, "T", function()
        motion(1, true)
      end)

      vim.keymap.set({ "n", "x", "o" }, ";", function()
        require("leap-search").leap(nil, {
          engines = {
            { name = "string.find", plain = true, ignorecase = true },
            { name = "kensaku.query" },
          },
          experimental = {
            backspace = true,
            autojump = false,
            ctrl_v = true,
          },
          hl_group = "WarningMsg",
        }, { target_windows = { vim.api.nvim_get_current_win() } })
      end)

      local function search(back)
        local pat = vim.fn.getreg("/")
        if vim.o.hlsearch then
          vim.o.hlsearch = false
          vim.o.hlsearch = true
        end
        local leapable = require("leap-search").leap(pat, {}, { backward = back })
        if not leapable then
          vim.cmd("normal! " .. (back and "N" or "n"))
        end
      end

      set_keymap("n", "gn", function()
        search()
      end)
      set_keymap("n", "gN", function()
        search(true)
      end)

      local function search_win()
        local pat = vim.fn.getreg("/")
        require("leap-search").leap(pat, {}, { target_windows = { vim.api.nvim_get_current_win() } })
      end

      local function search_ref()
        local ref = require("illuminate.reference").buf_get_references(vim.api.nvim_get_current_buf())
        if not ref or #ref == 0 then
          return false
        end

        local targets = {}
        for _, v in pairs(ref) do
          table.insert(targets, {
            pos = { v[1][1] + 1, v[1][2] + 1 },
          })
        end

        require("leap").leap({ targets = targets, target_windows = { vim.api.nvim_get_current_win() } })

        return true
      end

      set_keymap("n", "<Plug>(leap-prefix)*", search_win)
      set_keymap("n", "*", [[<Cmd>lua require("lasterisk").search()<CR><Plug>(leap-prefix)]])
      set_keymap("n", "g*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR><Plug>(leap-prefix)]])
      set_keymap("x", "*", function()
        require("lasterisk").search({ is_whole = false })
        return "<C-\\><C-N>"
      end, { expr = true })

      set_keymap("n", "#", function()
        if search_ref() then
          return
        end
        require("lasterisk").search()
        search_win()
      end)
      set_keymap("x", "#", function()
        require("lasterisk").search({ is_whole = false })
        vim.schedule(search_win)
        return "<C-\\><C-N>"
      end, { expr = true })
      set_keymap("n", "g#", function()
        require("lasterisk").search({ is_whole = false })
        search_win()
      end)
    end,
  },

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
      local get_query = vim.treesitter.query and vim.treesitter.query.get or vim.treesitter.get_query -- since Nvim 0.9
      require("nvim-treesitter.configs").setup({
        parser_install_dir = treesitterpath,
        ensure_installed = "all",
        highlight = {
          enable = true,
          disable = function(lang)
            local ok = pcall(get_query, lang, "highlights")
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
      register("bash", "sh")
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
  {
    "atusy/tsnode-marker.nvim",
    lazy = true,
    dir = "~/ghq/github.com/atusy/tsnode-marker.nvim",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = utils.augroup,
        pattern = "markdown",
        callback = function(ctx)
          -- blank target requires capture group @tsodemarker
          -- dot_config/nvim/after/queries/markdown/highlights.scm
          require("tsnode-marker").set_automark(ctx.buf, {
            -- target = { "code_fence_content" },
            -- hl_group = "@illuminate",
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
      vim.api.nvim_set_hl(0, "@tsnodemarker", { link = "@illuminate" })
    end,
  },

  -- autopairs
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    config = function()
      require("mini.pairs").setup({})
    end,
    cond = false,
  },
  {
    "hrsh7th/nvim-insx",
    event = "InsertEnter",
    config = function()
      require("insx.preset.standard").setup()
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
