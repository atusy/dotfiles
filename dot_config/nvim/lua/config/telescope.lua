local vim = vim
local utils = require('utils')
local set_keymap = utils.set_keymap

local function setup(_)
  local Telescope = require('telescope')
  local TelescopeBuiltin = require('telescope.builtin')
  local telescope_keymaps_filter = {
    fern = "'fern-action ",
    ["gin-status"] = "'gin-action "
  }
  local function telescope_keymaps()
    local ft = vim.api.nvim_buf_get_option(0, "filetype")
    TelescopeBuiltin.keymaps({
      modes = { vim.api.nvim_get_mode().mode },
      default_text = telescope_keymaps_filter[ft] or "☆",
    })
  end

  local function telescope_find_files()
    --[[ if os.execute("git rev-parse") == 0 then
      TelescopeBuiltin.git_files({
        show_untracked = true,
        recurse_submodules = true
      })
      return
    end ]]
    TelescopeBuiltin.find_files({
      hidden = true,
      search_dirs = { ".", "__ignored" },
    })
  end

  Telescope.setup({
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        -- the default case_mode is "smart_case"
      }
    }
  })
  require('aerial').setup()
  Telescope.load_extension('aerial')
  Telescope.load_extension('fzf')

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
    local picker = TelescopeBuiltin.treesitter
    if vim.tbl_contains({ "filetype" }, vim.bo.filetype) then
      picker = require('telescope._extensions').manager.aerial.aerial
    end
    picker({ sorter = filter_only_sorter() })
  end

  set_keymap('n', 's', '<Plug>(telescope)')
  for _, v in pairs {
    { 'n', '<Plug>(telescope)<CR>', 'builtin' },
    -- sa is occupied by sandwitch
    { 'n', '<Plug>(telescope)b', 'buffers' },
    { 'n', '<Plug>(telescope)c', 'commands' },
    -- sd is occupied by sandwitch
    -- se is occupied by emoji-prefix
    { 'n', '<Plug>(telescope)f', 'git_files or find_files', telescope_find_files },
    { 'n', '<Plug>(telescope)g', 'live_grep' },
    { 'n', '<Plug>(telescope)h', 'help_tags' },
    { 'n', '<Plug>(telescope)j', 'jumplist' },
    { 'n', '<Plug>(telescope)o', 'outline', telescope_outline },
    -- sr is occupied by sandwitch
    { 'n', '<Plug>(telescope)s', 'keymaps', telescope_keymaps },
    { 'n', '<Plug>(telescope)q', 'quickfixhistory' },
    { 'n', "<Plug>(telescope)'", 'marks' },
    { 'n', '<Plug>(telescope)"', 'registers' },
    { 'n', '<Plug>(telescope).', 'resume' },
    { 'n', '<Plug>(telescope)/', 'current_buffer_fuzzy_find' },
    { 'n', '<Plug>(telescope)?', 'man_pages' },
    { 'n', 'q;', 'command_history' },
    { 'n', 'q:', 'command_history' },
    { 'n', 'q/', 'search_history' },
    { 'i', "<C-R>'", 'registers' },
    { 'n', '<Plug>(C-G)<C-S>', 'git_status' },
    { 'n', '<Plug>(C-G)<C-M>', 'keymaps' },
    { 'n', '<Plug>(C-G)<CR>', 'keymaps' },
    { { 'v', 'i', 'x' }, '<C-G><C-M>', 'keymaps', telescope_keymaps },
    { { 'v', 'i', 'x' }, '<C-G><CR>', 'keymaps', telescope_keymaps },
  } do
    set_keymap(v[1], v[2], v[4] or TelescopeBuiltin[v[3]], { desc = 'telescope ' .. v[3] })
  end

  -- emoji
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values

  local function search_filelines(fname, pat)
    return vim.tbl_filter(
      function(x) return vim.fn.match(x, pat) ~= -1 end,
      vim.fn.readfile(fname)
    )
  end

  local regex_emoji = '[' ..
      [[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF\U00002500-\U00002BEF\U00002702-\U000027B0\U00002702-\U000027B0\U0001f926-\U0001f937\U00010000-\U0010ffff\u2640-\u2642\u2600-\u2B55\u200d\u23cf\u23e9\u231a\ufe0f\u3030]]
      .. ']'

  local prefix_emoji = function(buf, sources)
    buf = buf or vim.api.nvim_get_current_buf()
    sources = sources or { '.gitmessage' }

    -- Search for candidates
    local emoji_lines = {}
    for _, fname in ipairs(sources) do
      if #emoji_lines ~= 0 then
        break
      end
      if vim.fn.findfile(fname) ~= '' then
        emoji_lines = search_filelines(fname, regex_emoji)
      end
    end
    if #emoji_lines == 0 then return end

    -- find emoji
    pickers.new({}, {
      previewer = false,
      prompt_title = "Emoji Prefix",
      finder = finders.new_table { results = emoji_lines },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(
          function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local emoji = vim.fn.matchstr(selection[1], regex_emoji)
            if (emoji ~= '') then
              vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, { emoji })
            end
          end
        )
        return true
      end
    }):find()
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('prefix-emoji', {}),
    pattern = 'gitcommit',
    callback = function(args)
      set_keymap('n', '<Plug>(telescope)e', prefix_emoji, { buffer = args.buf })
      local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)
      if vim.fn.match(line, '^' .. regex_emoji) == -1 then
        vim.schedule(function() prefix_emoji(args.buf) end)
      end
    end
  })
end

return {
  deps = {
    'nvim-telescope/telescope.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim',
      run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' },
    -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
    { 'stevearc/aerial.nvim' },
  },
  setup = setup
}
