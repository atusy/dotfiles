local vim = vim
local M = {}

function M.require(name)
  pcall(function() require('plenary.reload').reload_module(name) end)
  return require(name)
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
  if opt.desc then
    opt.desc = '☆' .. opt.desc
  elseif type(rhs) == "string" then
    opt.desc = '☆' .. rhs
  end
  set_keymap(mode, lhs, rhs, opt)
end

function M.has_lsp_client(bufnr)
  return #vim.lsp.buf_get_clients(bufnr or 0) > 0
end

function M.attach_lsp(filetype)
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
