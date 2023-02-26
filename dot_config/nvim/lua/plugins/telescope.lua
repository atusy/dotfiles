local utils = require("atusy.utils")
local set_keymap, set_palette = utils.set_keymap, utils.set_palette

local function filter_only_sorter(sorter)
  sorter = sorter or require("telescope.config").values.file_sorter()
  local base_scorer = sorter.scoring_function
  local score_match = require("telescope.sorters").empty().scoring_function()
  sorter.scoring_function = function(self, prompt, line)
    local score = base_scorer(self, prompt, line)
    if score <= 0 then
      return -1
    else
      return score_match
    end
  end
  return sorter
end

local function telescope_outline()
  local picker
  if vim.tbl_contains({ "markdown" }, vim.bo.filetype) then
    local ok, aerial = pcall(function()
      return require("telescope._extensions").manager.aerial.aerial
    end)
    picker = ok and aerial
  end
  (picker or require("telescope.builtin").treesitter)({ sorter = filter_only_sorter() })
end

local telescope_keymaps_filter = {
  fern = "'fern-action ",
  ["gin-status"] = "'gin-action ",
}

local function telescope_keymaps()
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  require("telescope.builtin").keymaps({
    modes = { vim.api.nvim_get_mode().mode },
    default_text = vim.b.telescope_keymaps_default_text or telescope_keymaps_filter[ft] or utils.star,
  })
end

local function telescope(key)
  return "<Cmd>Telescope " .. key .. "<CR>"
end

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

local function setup(_)
  require("atusy.mappings-extra")
  local Telescope = require("telescope")
  Telescope.setup({
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
  Telescope.load_extension("aerial")
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
    init = function()
      setup_memo()
      local leader = "s"
      for _, v in pairs({
        { "n", leader .. "<CR>", "builtin" },
        -- sa is occupied by sandwich
        { "n", leader .. "b", "buffers" },
        { "n", leader .. "c", "commands" },
        -- sd is occupied by sandwich
        -- se is occupied by emoji-prefix
        { "n", leader .. "f", "find_files" },
        { "n", leader .. "g", "live_grep" },
        {
          "n",
          leader .. "h",
          "help_tags",
          function()
            pcall(require("atusy.lazy").load_all)
            require("telescope.builtin").help_tags()
          end,
        },
        { "n", leader .. "<Tab>", "jumplist" },
        { "n", leader .. "o", "outline", telescope_outline },
        -- sr is occupied by sandwich
        { "n", leader .. "s", "keymaps normal favorites", telescope_keymaps },
        { "n", leader .. "m", "keymaps" },
        { "n", leader .. "q", "quickfixhistory" },
        { "n", leader .. [[']], "marks" },
        { "n", leader .. [["]], "registers" },
        { "n", leader .. ".", "resume" },
        { "n", leader .. "/", "current_buffer_fuzzy_find" },
        { "n", leader .. "?", "man_pages" },
        { "n", "q;", "command_history" },
        -- { 'n', 'q:', 'command_history' }, -- prefer cmdbuf.nvim
        { "n", "q/", "search_history" },
        { "i", "<C-R>'", "registers" },
        { "n", "<Plug>(C-G)<C-S>", "git_status" },
        -- { 'n', '<Plug>(C-G)<C-M>', 'keymaps' },
        -- { 'n', '<Plug>(C-G)<CR>', 'keymaps' },
        -- { { 'i', 'x' }, '<C-G><C-M>', 'keymaps', telescope_keymaps },
        -- { { 'i', 'x' }, '<C-G><CR>', 'keymaps', telescope_keymaps },
      }) do
        set_keymap(v[1], v[2], v[4] or telescope(v[3]), { desc = "telescope " .. v[3] })
      end

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
    end,
    config = setup,
  },
  {
    "stevearc/aerial.nvim",
    lazy = true,
    init = function()
      set_keymap("n", "gO", function()
        require("aerial").open()
      end)
    end,
    config = function()
      require("aerial").setup()
    end,
  },
  -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
}
