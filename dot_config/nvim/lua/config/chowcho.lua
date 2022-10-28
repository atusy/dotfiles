local vim = vim

local safely = require('utils').safely
local set_keymap = require('utils').set_keymap

local setup = function()
  require 'chowcho'.setup({
    use_exclude_default = false,
    exclude = function(_, _) return false end
  })
  local _chowcho_run = require 'chowcho'.run
  local _chowcho_bufnr = function(winid)
    return vim.api.nvim_win_call(winid, function()
      return vim.fn.bufnr('%'), vim.opt_local
    end)
  end
  local _chowcho_buffer = function(winid, bufnr, opt_local)
    return vim.api.nvim_win_call(winid, function()
      local old = _chowcho_bufnr(0)
      vim.cmd("buffer " .. bufnr)
      if opt_local ~= nil then
        vim.opt_local = opt_local
      end
      return old
    end)
  end

  local function chowcho_focus()
    -- Focues window
    if #vim.api.nvim_tabpage_list_wins(0) > 2 then
      _chowcho_run(
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
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local nwins = #wins
    if nwins == 1 then
      if #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd("tabclose")
      end
      return
    end
    if nwins == 2 then
      local curwin = vim.api.nvim_get_current_win()
      for _, w in ipairs(wins) do
        if w ~= curwin then
          vim.api.nvim_win_hide(w)
          return
        end
      end
    end
    if nwins > 2 then
      _chowcho_run(safely(vim.api.nvim_win_hide))
    end
  end

  -- set_keymap({ '', 't' }, '<C-W>c', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><Space>', _chowcho_hide)
  set_keymap({ '', 't' }, '<C-W><C-Space>', _chowcho_hide)

  local function _chowcho_edit()
    -- Edits buffer from the selected in the current
    if #vim.api.nvim_tabpage_list_wins(0) < 1 then return end
    _chowcho_run(
      safely(function(n)
        local bufnr, opt_local = _chowcho_bufnr(n)
        _chowcho_buffer(0, bufnr, opt_local)
      end),
      {
        use_exclude_default = false,
        exclude = function(buf, _)
          return vim.api.nvim_buf_call(buf, function()
            return vim.api.nvim_buf_get_option(0, "modifiable") == false
          end)
        end
      }
    )
  end

  set_keymap({ '', 't' }, '<C-W>e', _chowcho_edit)
  set_keymap({ '', 't' }, '<C-W><C-E>', _chowcho_edit)

  local function _chowcho_exchange()
    -- Swaps buffers between windows
    if #vim.api.nvim_tabpage_list_wins(0) <= 2 then
      vim.cmd("wincmd x")
      return
    end
    _chowcho_run(
      safely(function(n)
        if n == vim.api.nvim_get_current_win() then
          return
        end
        local bufnr0, opt_local0 = _chowcho_bufnr(0)
        local bufnrn, opt_localn = _chowcho_buffer(n, bufnr0, opt_local0)
        _chowcho_buffer(0, bufnrn, opt_localn)
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
