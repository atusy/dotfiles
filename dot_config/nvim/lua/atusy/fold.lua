local M = {}

local loaded = false

function M.loaded()
  if not loaded then
    loaded = vim.o.foldenable or vim.wo.foldenable
  end
  return loaded
end

--- my foldtext
---
--- vim.opt.foldtext = [[v:lua.require("atusy.fold").foldtext()]]
function M.foldtext()
  if not M.loaded() then
    return {}
  end
  local foldtext = require("atusy.treesitter").foldtext()
  if #foldtext == 0 then
    for _, line in pairs(vim.api.nvim_buf_get_lines(0, vim.v.foldstart - 1, vim.v.foldend, false)) do
      if line:len() > 0 then
        return line
      end
    end
  end
  return foldtext
end

--- my foldexpr
---
--- vim.opt.foldexpr = [[v:lua.require("atusy.fold").foldexpr()]]
function M.foldexpr()
  if not M.loaded() then
    return "0"
  end
  return vim.treesitter.foldexpr()
end

return M
