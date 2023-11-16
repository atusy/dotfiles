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
  vim.keymap.set("n", leader .. "<CR>", telescope("builtin"))
  vim.keymap.set("n", leader .. "<Tab>", telescope("jumplist"))
  -- sa is occupied by mini.surround
  vim.keymap.set("n", leader .. "b", telescope("buffers"))
  vim.keymap.set("n", leader .. "c", telescope("commands"))
  -- sd is occupied by mini.surround
  vim.keymap.set("n", leader .. "f", telescope("find_files"))
  vim.keymap.set("n", leader .. "g", telescope("live_grep"))
  vim.keymap.set("n", leader .. "h", function()
    require("atusy.lazy").load_all()
    require("telescope.builtin").help_tags()
  end, { desc = "Telescope lazy help_tags" })
  vim.keymap.set("n", leader .. "o", function()
    require("plugins.telescope.picker").outline()
  end, { desc = "Telescope custom outline" })
  -- sr is occupied by mini.surround
  vim.keymap.set("n", leader .. "s", function()
    require("atusy.lazy").load_all()
    local failed = require("atusy.keymap.palette").update()
    -- local failed = require("atusy.utils").update_palette()
    if #failed > 0 then
      vim.print(failed)
    end
    require("plugins.telescope.picker").keymaps()
  end, { desc = "Telescope normal favorite keymaps" })
  vim.keymap.set("n", leader .. "m", function()
    local failed = require("atusy.keymap.palette").update()
    -- local failed = require("atusy.utils").update_palette()
    if #failed > 0 then
      vim.print(failed)
    end
    require("telescope.builtin").keymaps()
  end)
  vim.keymap.set("n", leader .. "q", telescope("quickfixhistory"))
  vim.keymap.set("n", leader .. [[']], telescope("marks"))
  vim.keymap.set("n", leader .. [["]], telescope("registers"))
  vim.keymap.set("n", leader .. ".", telescope("resume"))
  vim.keymap.set("n", leader .. "/", telescope("current_buffer_fuzzy_find"))
  vim.keymap.set("n", leader .. "?", telescope("man_pages"))
  vim.keymap.set("n", "q:", telescope("command_history"))
  vim.keymap.set("n", "q/", telescope("search_history"))
  vim.keymap.set("n", "<Plug>(C-G)<C-S>", telescope("git_status"))
end

local function telescope_config(_)
  local Telescope = require("telescope")
  Telescope.setup({
    defaults = {
      mappings = {
        i = {
          ["<C-J>"] = false, -- to support skkeleton.vim
          ["<C-P>"] = require("telescope.actions.layout").toggle_preview,
        },
        n = {
          K = function(_)
            vim.print(require("telescope.actions.state").get_selected_entry())
          end,
          ["<C-K>"] = function(prompt_bufnr)
            vim.print(require("telescope.actions.state").get_current_picker(prompt_bufnr))
          end,
        },
      },
      preview = {
        filetype_hook = function(filepath, bufnr, opts)
          if filepath:match(".*%.png") then
            -- in general, binary file is not previewed, but git_files try previewing it
            local putils = require("telescope.previewers.utils")
            putils.set_preview_message(bufnr, opts.winid, filepath)
            return false
          end
          return true
        end,
      },
      dynamic_preview_title = true,
    },
    pickers = {
      find_files = {
        hidden = true,
        follow = true,
        search_dirs = { ".", "__ignored" },
      },
      live_grep = {
        additional_args = function(_)
          return { "--hidden" }
        end,
      },
      command_history = {
        attach_mappings = function(_, map)
          map({ "i", "n" }, "<CR>", require("telescope.actions").edit_command_line)
          return true
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
    "https://github.com/nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "https://github.com/nvim-lua/plenary.nvim",
      { "https://github.com/nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- 'stevearc/aerial.nvim', -- can be implicit
    },
    init = telescope_init,
    config = telescope_config,
  },
  {
    "https://github.com/stevearc/aerial.nvim",
    lazy = true,
    cmd = { "Telescope" },
    dependencies = { "https://github.com/nvim-telescope/telescope.nvim" },
    init = function()
      vim.keymap.set("n", "gO", [[<Cmd>lua require("aerial").open()<CR>]])
    end,
    config = function()
      require("aerial").setup()
      require("telescope").load_extension("aerial")
    end,
  },
  -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
}
