local function telescope(key, opts)
  return function()
    require("telescope.builtin")[key](opts)
  end
end

local function telescope_init()
  local leader = "s"
  vim.keymap.set("n", leader .. "<CR>", telescope("builtin"))
  -- sa is occupied by mini.surround
  vim.keymap.set("n", leader .. "b", telescope("buffers"))
  vim.keymap.set("n", leader .. "c", telescope("commands"))
  -- sd is occupied by mini.surround
  vim.keymap.set("n", leader .. "f", telescope("find_files"))
  vim.keymap.set("n", leader .. "g", telescope("live_grep"))
  vim.keymap.set("n", leader .. "h", [[<Cmd>lua require("plugins.telescope.picker").help_tags()<CR>]])
  vim.keymap.set("n", leader .. "j", telescope("jumplist"))
  vim.keymap.set("n", leader .. "m", [[<Cmd>lua require("plugins.telescope.picker").keymaps({})<CR>]]) -- builtin keymaps
  vim.keymap.set("n", leader .. "o", [[<Cmd>lua require("plugins.telescope.picker").outline()<CR>]])
  vim.keymap.set("n", leader .. "q", telescope("quickfixhistory"))
  -- sr is occupied by mini.surround
  vim.keymap.set("n", leader .. "s", [[<Cmd>lua require("plugins.telescope.picker").keymaps(nil)<CR>]]) -- comand palette
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
  require("telescope").setup({
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
            require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, filepath)
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
      fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = "smart_case" },
    },
  })
  require("telescope").load_extension("fzf")
end

return {
  {
    "https://github.com/nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "https://github.com/nvim-lua/plenary.nvim",
      { "https://github.com/nvim-telescope/telescope-fzf-native.nvim", build = "make" },
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
