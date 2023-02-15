local set_keymap = require("atusy.utils").set_keymap
local M = {}

function M.toggle_left_drag()
  for _, m in pairs(vim.api.nvim_get_keymap('n')) do
    if m.lhs == '<LeftDrag>' then
      if m.rhs == '' then
        vim.keymap.del('n', '<LeftDrag>')
        vim.keymap.del('n', '<LeftRelease>')
      end
      return
    end
  end
  set_keymap('n', '<LeftDrag>', '<Nop>')
  set_keymap('n', '<LeftRelease>', '<Nop>')
end

return M
