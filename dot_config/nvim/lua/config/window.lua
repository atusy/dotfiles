local vim = vim
local api = vim.api
local list_wins = api.nvim_tabpage_list_wins

local safely = require('utils').safely
local set_keymap = require('utils').set_keymap

local function is_win_focusable(win)
  local config = api.nvim_win_get_config(win)
  return config.focusable
end

local function count_win_focusable(wins)
  return #vim.tbl_filter(is_win_focusable, wins)
end

local setup_chowcho = function()
  require 'chowcho'.setup({
    use_exclude_default = false,
    exclude = function(_, _) return false end
  })
  local run = require 'chowcho'.run

  local function chowcho_focus()
    -- Focues window
    if count_win_focusable(list_wins(0)) > 2 then
      run(
        safely(api.nvim_set_current_win),
        {
          use_exclude_default = false,
          exclude = function(_, win)
            return api.nvim_win_get_config(win).focusable == false
          end
        }
      )
    else
      vim.cmd('wincmd w')
    end
  end

  set_keymap({ '', 't' }, '<C-W><C-W>', chowcho_focus)
  set_keymap({ '', 't' }, '<C-W>w', chowcho_focus)

  local function _chowcho_hide()
    local nwins = #list_wins(0)
    if nwins == 1 and api.nvim_get_current_tabpage() ~= 1 then
      vim.cmd("tabclose")
    elseif nwins == 2 then
      vim.cmd("wincmd o")
    elseif nwins > 2 then
      run(safely(api.nvim_win_hide))
    end
  end

  -- set_keymap({ '', 't' }, '<C-W>c', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><Space>', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><C-Space>', _chowcho_hide)

  local function _chowcho_edit()
    -- Edits buffer from the selected in the current
    if #list_wins(0) < 1 then return end
    run(
      safely(function(n)
        api.nvim_win_set_buf(0, api.nvim_win_get_buf(n))
      end),
      {
        use_exclude_default = false,
        exclude = function(_, win)
          local winconf = api.nvim_win_get_config(win)
          return winconf.external or winconf.relative ~= ""
        end
      }
    )
  end

  set_keymap({ '', 't' }, '<C-W>e', _chowcho_edit)
  set_keymap({ '', 't' }, '<C-W><C-E>', _chowcho_edit)

  local function _chowcho_exchange()
    -- Swaps buffers between windows
    -- also moves between windows to apply styler.nvim theming
    if #list_wins(0) <= 2 then
      vim.cmd("wincmd x")
      return
    end
    run(
      safely(function(n)
        local cur = api.nvim_get_current_win()
        if n == cur then return end
        local bufnr0 = api.nvim_win_get_buf(cur)
        local bufnrn = api.nvim_win_get_buf(n)
        api.nvim_win_set_buf(cur, bufnrn)
        api.nvim_win_set_buf(n, bufnr0)
      end),
      {
        use_exclude_default = false,
        exclude = function(_, win)
          local winconf = api.nvim_win_get_config(win)
          return winconf.external or winconf.relative ~= ""
        end
      }
    )
  end

  set_keymap({ '', 't' }, '<C-W><C-X>', _chowcho_exchange)
  set_keymap({ '', 't' }, '<C-W>x', _chowcho_exchange)
end

local function setup()
  local group = vim.api.nvim_create_augroup('config.window', {})
  vim.api.nvim_create_autocmd('WinNew', {
    group = group,
    once = true,
    callback = setup_chowcho
  })
end

return {
  deps = {
    { 'tkmpypy/chowcho.nvim' },
  },
  setup = setup,
}
