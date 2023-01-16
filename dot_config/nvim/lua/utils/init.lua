local M = {}

M.augroup = 'atusy-init-lua'
M.datapath = vim.fn.stdpath('data')

function M.require(name)
  pcall(function() require('plenary.reload').reload_module(name) end)
  return require(name)
end

function M.require_lazy(name)
  return setmetatable({}, {
    __index = function(self, key)
      for k, v in pairs(M.require(name)) do
        self[k] = v
      end
      return self[key]
    end
  })
end

function M.safely(f)
  return function(...) pcall(f, ...) end
end

M.star = '☆'

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
  if opt.fav ~= false then
    if opt.desc then
      opt.desc = M.star .. opt.desc
    elseif type(rhs) == "string" then
      opt.desc = M.star .. rhs
    end
  end
  opt.fav = nil
  set_keymap(mode, lhs, rhs, opt)
end

local ready = false
function M.setup(force)
  if ready and not force then
    -- avoid accidental reset of augroup
    vim.notify(
      'utils.setup has been done before. Force re-run with utils.setup(true).',
      vim.log.levels.ERROR
    )
    return
  end
  vim.api.nvim_create_augroup(M.augroup, {})
  ready = true
end

return M
