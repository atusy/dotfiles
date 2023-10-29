local M = {}

M.augroup = "atusy-init-lua"
M.datapath = vim.fn.stdpath("data")

function M.require(name)
  pcall(function()
    require("plenary.reload").reload_module(name)
  end)
  return require(name)
end

local function default_handler(err)
  vim.notify(err, vim.log.levels.ERROR)
end

function M.safely(f, default, handler)
  return function(...)
    local ok, res = pcall(f, ...)
    if not ok then
      return default, (handler or default_handler)(res)
    end
    return res
  end
end

M.star = "☆"

local ready = false
function M.setup(force)
  if ready and not force then
    -- avoid accidental reset of augroup
    vim.notify("utils.setup has been done before. Force re-run with utils.setup(true).", vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_create_augroup(M.augroup, {})
  ready = true
end

return M
