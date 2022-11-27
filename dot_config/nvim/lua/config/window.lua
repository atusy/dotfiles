local vim = vim

local safely = require('utils').safely
local set_keymap = require('utils').set_keymap

local function list_win_config(tabpage)
  return vim.tbl_map(
    vim.api.nvim_win_get_config,
    vim.api.nvim_tabpage_list_wins(tabpage or 0)
  )
end

local function is_win_focusable(config)
  return config.focusable
end

local function count_win_focusable(tabpage)
  return #vim.tbl_filter(is_win_focusable, list_win_config(tabpage))
end

local setup = function()
  require 'chowcho'.setup({
    use_exclude_default = false,
    exclude = function(_, _) return false end
  })
  local run = require 'chowcho'.run

  local function chowcho_focus()
    -- Focues window
    if count_win_focusable(0) > 2 then
      run(
        safely(vim.api.nvim_set_current_win),
        {
          use_exclude_default = false,
          exclude = function(_, win)
            local config = vim.api.nvim_win_get_config(win)
            return config.focusable == false
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
    local nwins = #vim.api.nvim_tabpage_list_wins(0)
    if nwins == 1 and #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabclose")
    elseif nwins == 2 then
      vim.cmd("wincmd o")
    elseif nwins > 2 then
      run(safely(vim.api.nvim_win_hide))
    end
  end

  -- set_keymap({ '', 't' }, '<C-W>c', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><Space>', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><C-Space>', _chowcho_hide)

  local function _chowcho_edit()
    -- Edits buffer from the selected in the current
    if #vim.api.nvim_tabpage_list_wins(0) < 1 then return end
    run(
      safely(function(n)
        vim.api.nvim_win_set_buf(0, vim.api.nvim_win_get_buf(n))
      end),
      {
        use_exclude_default = false,
        exclude = function(_, win)
          local winconf = vim.api.nvim_win_get_config(win)
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
    if #vim.api.nvim_tabpage_list_wins(0) <= 2 then
      vim.cmd("wincmd x")
      return
    end
    run(
      safely(function(n)
        local cur = vim.api.nvim_get_current_win()
        if n == cur then return end
        local bufnr0 = vim.api.nvim_win_get_buf(cur)
        local bufnrn = vim.api.nvim_win_get_buf(n)
        vim.api.nvim_win_set_buf(cur, bufnrn)
        vim.api.nvim_win_set_buf(n, bufnr0)
      end),
      {
        use_exclude_default = false,
        exclude = function(_, win)
          local winconf = vim.api.nvim_win_get_config(win)
          return winconf.external or winconf.relative ~= ""
        end
      }
    )
  end

  set_keymap({ '', 't' }, '<C-W><C-X>', _chowcho_exchange)
  set_keymap({ '', 't' }, '<C-W>x', _chowcho_exchange)
end

return {
  deps = {
    { 'tkmpypy/chowcho.nvim' },
  },
  setup = setup,
}
