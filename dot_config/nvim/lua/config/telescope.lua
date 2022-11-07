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
    TelescopeBuiltin.find_files({
      hidden = true,
      search_dirs = { ".", "./.ignored" },
    })
  end

  Telescope.setup()
  Telescope.load_extension('fzf')
  for _, v in pairs {
    { 'n', 'mb', 'buffers' },
    { 'n', 'mc', 'commands' },
    { 'n', 'mf', 'find_files', telescope_find_files },
    { 'n', 'mg', 'live_grep' },
    { 'n', 'mh', 'help_tags' },
    { 'n', '<Plug>(C-G)<C-S>', 'git_status' },
    { 'n', 'mk', 'marks' },
    { 'n', 'mm', 'keymaps', telescope_keymaps },
    { { 'n' }, '<Plug>(C-G)<C-M>', 'keymaps' },
    { { 'n' }, '<Plug>(C-G)<CR>', 'keymaps' },
    { { 'v', 'i', 'x' }, '<C-G><C-M>', 'keymaps', telescope_keymaps },
    { { 'v', 'i', 'x' }, '<C-G><CR>', 'keymaps', telescope_keymaps },
    { 'n', 'ml', 'git_files' },
    { 'n', "m'", 'registers' },
    { 'i', "<C-R>'", 'registers' },
    { 'n', 'm.', 'resume' },
    { 'n', 'mt', 'treesitter' },
    { 'n', 'm/', 'current_buffer_fuzzy_find' },
    { 'n', 'q;', 'command_history' },
    { 'n', 'q:', 'command_history' },
    { 'n', 'q/', 'search_history' },
  } do
    set_keymap(v[1], v[2], v[4] or TelescopeBuiltin[v[3]], { desc = 'telescope ' .. v[3] })
  end
  for k, v in pairs(TelescopeBuiltin) do
    if type(v) == "function" then
      set_keymap('n', '<Plug>(telescope.' .. k .. ')', v)
    end
  end

  -- emoji
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values

  local function search_lines(lines, pat)
    local matches = {}
    for _, line in ipairs(lines) do
      if vim.fn.match(line, pat) ~= -1 then
        table.insert(matches, line)
      end
    end
    return matches
  end

  local function search_file(fname, pat)
    return search_lines(vim.fn.readfile(fname), pat)
  end

  local regex_emoji = '[' ..
      [[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF\U00002500-\U00002BEF\U00002702-\U000027B0\U00002702-\U000027B0\U0001f926-\U0001f937\U00010000-\U0010ffff\u2640-\u2642\u2600-\u2B55\u200d\u23cf\u23e9\u231a\ufe0f\u3030]]
      .. ']'

  local prefix_emoji = function(bufnr, alt)
    bufnr = bufnr or 0
    alt = alt or { '.gitmessage' }
    local win = vim.api.nvim_get_current_win()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Test if emoji is required
    if vim.fn.match(lines[0], regex_emoji) ~= -1 then
      return
    end

    -- Search for candidates
    local emoji_lines = search_lines(lines, regex_emoji)
    for _, fname in ipairs(alt) do
      if #emoji_lines ~= 0 then
        break
      end
      if vim.fn.findfile(fname) ~= '' then
        emoji_lines = search_file(fname, regex_emoji)
      end
    end
    if #emoji_lines == 0 then
      return
    end

    -- Create temporary buffer and floating window to run telescope
    -- local tempbuf = vim.api.nvim_create_buf(false, true)
    -- vim.api.nvim_buf_set_lines(tempbuf, 0, -1, false, emoji_lines)
    -- local floating = vim.api.nvim_open_win(tempbuf, true, {
    --   relative="editor",
    --   width=1,
    --   height=1,
    --   row=0,
    --   col=0
    -- })

    -- find emoji
    pickers.new({}, {
      previewer = false,
      prompt_title = "colors",
      finder = finders.new_table {
        results = emoji_lines
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- actions.close:enhance{
        --   post = function()
        --     vim.api.nvim_win_close(floating, true)
        --     vim.api.nvim_buf_delete(tempbuf, {force=true})
        --   end
        -- }
        local _ = map
        actions.select_default:replace(
          function()
            actions.close(prompt_bufnr)
            vim.api.nvim_set_current_win(win)
            local selection = action_state.get_selected_entry()
            local emoji = vim.fn.matchstr(selection[1], regex_emoji)
            if (emoji ~= '') then
              vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, { emoji })
            end
          end
        )
        return true
      end
    }):find()
  end

  vim.api.nvim_create_user_command('EmojiPrefix', function() prefix_emoji() end, {})
  set_keymap('', '<Plug>(emoji-prefix)', function() prefix_emoji() end)
  set_keymap('n', 'me', '<Plug>(emoji-prefix)')
end

return {
  deps = {
    'nvim-telescope/telescope.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    -- { 'tknightz/telescope-termfinder.nvim' },  -- finds toggleterm terminals
  },
  setup = setup
}
