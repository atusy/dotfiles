local utils = require('utils')
local set_keymap = utils.set_keymap

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
      return require('telescope._extensions').manager.aerial.aerial
    end)
    picker = ok and aerial
  end
  (picker or require 'telescope.builtin'.treesitter)({ sorter = filter_only_sorter() })
end

local telescope_keymaps_filter = {
  fern = "'fern-action ",
  ["gin-status"] = "'gin-action "
}

local function telescope_keymaps()
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  require 'telescope.builtin'.keymaps({
    modes = { vim.api.nvim_get_mode().mode },
    default_text = vim.b.telescope_keymaps_default_text or telescope_keymaps_filter[ft] or utils.star,
  })
end

-- emoji
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
  if not sources then
    local bufname = vim.api.nvim_buf_get_name(buf)
    if vim.endswith(bufname, '.git/COMMIT_EDITMSG') then
      sources = { vim.fs.dirname(vim.fs.dirname(bufname)) .. '/.gitmessage', '.gitmessage' }
    else
      sources = { '.gitmessage' }
    end
  end

  -- Search for candidates
  local emoji_lines = {}
  for _, fname in ipairs(sources) do
    if #emoji_lines ~= 0 then
      break
    end
    if vim.fn.filereadable(fname) == 1 then
      emoji_lines = search_filelines(fname, regex_emoji)
    end
  end
  if #emoji_lines == 0 then return end

  -- find emoji
  require 'telescope.pickers'.new({}, {
    previewer = false,
    prompt_title = "Emoji Prefix",
    finder = require 'telescope.finders'.new_table { results = emoji_lines },
    sorter = require 'telescope.config'.values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      local action_state = require "telescope.actions.state"
      local actions = require "telescope.actions"
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

local function telescope(key) return "<Cmd>Telescope " .. key .. "<CR>" end

local function setup_memo()
  local memo = '~/Documents/memo'
  set_keymap(
    'n', '<Plug>(memo-new)', ':e ' .. memo .. '/',
    { desc = 'memo edit' }
  -- recommends https://github.com/jghauser/mkdir.nvim
  )
  set_keymap(
    'n', '<Plug>(memo-find-files)',
    function()
      require('telescope.builtin').find_files({ search_dirs = { memo } })
    end,
    { desc = 'memo find' }

  )
  set_keymap(
    'n', '<Plug>(memo-live-grep)',
    function()
      require('telescope.builtin').live_grep({ cwd = memo })
    end,
    { desc = 'memo grep' }
  )
end

local function setup(_)
  local Telescope = require('telescope')
  Telescope.setup({
    pickers = {
      find_files = {
        hidden = true,
        search_dirs = { ".", "__ignored" },
      }
    },
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
  Telescope.load_extension('aerial')
  Telescope.load_extension('fzf')
end

return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      -- 'stevearc/aerial.nvim', -- can be implicit
    },
    init = function()
      setup_memo()
      local leader = 's'
      for _, v in pairs {
        { 'n', leader .. '<CR>', 'builtin' },
        -- sa is occupied by sandwich
        { 'n', leader .. 'b', 'buffers' },
        { 'n', leader .. 'c', 'commands' },
        -- sd is occupied by sandwich
        -- se is occupied by emoji-prefix
        { 'n', leader .. 'f', 'find_files' },
        { 'n', leader .. 'g', 'live_grep' },
        { 'n', leader .. 'h', 'help_tags' },
        { 'n', leader .. 'j', 'jumplist' },
        { 'n', leader .. 'o', 'outline', telescope_outline },
        -- sr is occupied by sandwich
        { 'n', leader .. 's', 'keymaps normal favorites', telescope_keymaps },
        { 'n', leader .. 'm', 'keymaps' },
        { 'n', leader .. 'q', 'quickfixhistory' },
        { 'n', leader .. [[']], 'marks' },
        { 'n', leader .. [["]], 'registers' },
        { 'n', leader .. '.', 'resume' },
        { 'n', leader .. '/', 'current_buffer_fuzzy_find' },
        { 'n', leader .. '?', 'man_pages' },
        { 'n', 'q;', 'command_history' },
        -- { 'n', 'q:', 'command_history' }, -- prefer cmdbuf.nvim
        { 'n', 'q/', 'search_history' },
        { 'i', "<C-R>'", 'registers' },
        { 'n', '<Plug>(C-G)<C-S>', 'git_status' },
        -- { 'n', '<Plug>(C-G)<C-M>', 'keymaps' },
        -- { 'n', '<Plug>(C-G)<CR>', 'keymaps' },
        -- { { 'v', 'i', 'x' }, '<C-G><C-M>', 'keymaps', telescope_keymaps },
        -- { { 'v', 'i', 'x' }, '<C-G><CR>', 'keymaps', telescope_keymaps },
      } do
        set_keymap(v[1], v[2], v[4] or telescope(v[3]), { desc = 'telescope ' .. v[3] })
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = utils.augroup,
        pattern = 'gitcommit',
        callback = function(args)
          set_keymap('n', leader .. 'e', prefix_emoji, { buffer = args.buf })
          local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)
          if vim.fn.match(line, '^' .. regex_emoji) == -1 then
            vim.schedule(function() prefix_emoji(args.buf) end)
          end
        end
      })
    end,
    config = setup,
  },
  {
    'stevearc/aerial.nvim',
    lazy = true,
    init = function()
      set_keymap('n', 'gO', function() require('aerial').open() end)
    end,
    config = function() require('aerial').setup() end
  },
  -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
}
