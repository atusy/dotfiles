local vim = vim
local M = {}

local _require = require

function M.require(name)
  pcall(function() _require('plenary.reload').reload_module(name) end)
  return _require(name)
end

function M.safely(f)
  return function(...) pcall(f, ...) end
end

local set_keymap = vim.keymap.set
function M.set_keymap(mode, lhs, rhs, opt1, opt2)
  local opt = {}
  if opt2 then
    for _, o in ipairs({ opt1, opt2 }) do
      for k, v in pairs(o or {}) do
        opt[k] = v
      end
    end
  elseif opt1 then
    opt = opt1
  end
  set_keymap(mode, lhs, rhs, opt)
end

function M.has_lsp_client(bufnr)
  for _, _ in pairs(vim.lsp.buf_get_clients(bufnr or 0)) do
    return true
  end
  return false
end

M.attach_lsp = function(filetype)
  filetype = filetype or vim.api.nvim_buf_get_option(0, "filetype")
  local clients = {}
  for _, cl in ipairs(vim.lsp.get_active_clients()) do
    if cl.config and cl.config.filetypes then
      for _, ft in ipairs(cl.config.filetypes) do
        if ft == filetype then
          vim.lsp.buf_attach_client(0, cl.id)
          table.insert(clients, cl)
        end
      end
    end
  end
  return clients
end

return M
