local utils = require("atusy.utils")
local set_keymap, set_palette = utils.set_keymap, utils.set_palette

local function setup_memo()
  local memo = "~/Documents/memo"
  set_palette(
    "n",
    "memo edit",
    ":e " .. memo .. "/" -- recommends https://github.com/jghauser/mkdir.nvim
  )
  set_palette("n", "memo find", function()
    require("telescope.builtin").find_files({ search_dirs = { memo } })
  end)
  set_palette("n", "memo grep", function()
    require("telescope.builtin").live_grep({ cwd = memo })
  end)
end

local function telescope(key, opts)
  -- call builtin pickers as functions instead of <Cmd> mappings
  -- because lazy loading may fail if <Cmd> mappings are invoked
  -- immediately after VimEnter
  return function()
    require("telescope.builtin")[key](opts)
  end
end

local function telescope_init()
  local leader = "s"
  set_keymap("n", leader .. "<CR>", telescope("builtin"))
  set_keymap("n", leader .. "<Tab>", telescope("jumplist"))
  -- sa is occupied by mini.surround
  set_keymap("n", leader .. "b", telescope("buffers"))
  set_keymap("n", leader .. "c", telescope("commands"))
  -- sd is occupied by mini.surround
  set_keymap("n", leader .. "f", telescope("find_files"))
  set_keymap("n", leader .. "g", telescope("live_grep"))
  set_keymap("n", leader .. "h", function()
    pcall(require("atusy.lazy").load_all)
    require("telescope.builtin").help_tags()
  end, { desc = "Telescope lazy help_tags" })
  set_keymap("n", leader .. "o", function()
    require("plugins.telescope.picker").outline()
  end, { desc = "Telescope custom outline" })
  -- sp is occupied by emoji-prefix
  -- sr is occupied by mini.surround
  set_keymap("n", leader .. "s", function()
    require("plugins.telescope.picker").keymaps()
  end, { desc = "Telescope normal favorite keymaps" })
  set_keymap("n", leader .. "m", telescope("keymaps"))
  set_keymap("n", leader .. "q", telescope("quickfixhistory"))
  set_keymap("n", leader .. [[']], telescope("marks"))
  set_keymap("n", leader .. [["]], telescope("registers"))
  set_keymap("n", leader .. ".", telescope("resume"))
  set_keymap("n", leader .. "/", telescope("current_buffer_fuzzy_find"))
  set_keymap("n", leader .. "?", telescope("man_pages"))
  set_keymap("n", "q;", telescope("command_history"))
  -- q: is occupied by cmdbuf.nvim
  set_keymap("n", "q/", telescope("search_history"))
  set_keymap("n", "<Plug>(C-G)<C-S>", telescope("git_status"))

  setup_memo()
  vim.api.nvim_create_autocmd("FileType", {
    group = utils.augroup,
    pattern = "gitcommit",
    callback = function(args)
      local p = require("plugins.telescope.picker.git-prefix")
      set_keymap("n", leader .. "p", p.prefix_emoji, { buffer = args.buf })
      local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)
      if vim.fn.match(line, "^" .. p.regex_emoji) == -1 then
        vim.schedule(function()
          p.prefix_emoji(args.buf)
        end)
      end
    end,
  })
end

local function telescope_config(_)
  require("atusy.mappings-extra")
  local Telescope = require("telescope")
  Telescope.setup({
    defaults = {
      mappings = {
        i = {
          ["<C-J>"] = false, -- to support skkeleton.vim
          ["<C-P>"] = require("telescope.actions.layout").toggle_preview,
        },
        n = {
          K = function(prompt_bufnr)
            vim.print(require("telescope.actions.state").get_selected_entry())
          end,
          ["<C-K>"] = function(prompt_bufnr)
            vim.print(require("telescope.actions.state").get_current_picker(prompt_bufnr))
          end,
        },
      },
      dynamic_preview_title = true,
    },
    pickers = {
      find_files = {
        hidden = true,
        search_dirs = { ".", "__ignored" },
      },
      live_grep = {
        additional_args = function(opts)
          return { "--hidden" }
        end,
      },
    },
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        -- the default case_mode is "smart_case"
      },
    },
  })
  Telescope.load_extension("fzf")
end

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- 'stevearc/aerial.nvim', -- can be implicit
    },
    init = telescope_init,
    config = telescope_config,
  },
  {
    "stevearc/aerial.nvim",
    lazy = true,
    cmd = { "Telescope" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    init = function()
      set_keymap("n", "gO", function()
        require("aerial").open()
      end)
    end,
    config = function()
      require("aerial").setup()
      require("telescope").load_extension("aerial")
    end,
  },
  -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
}
